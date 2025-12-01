"""
Skill synthesis converts semantic clusters into Skill Cards.
"""

import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

from jsonschema import Draft7Validator

logger = logging.getLogger(__name__)


class SkillSynthesizer:
    """Create and update Skill Cards from clusters."""

    def __init__(self, config: Dict, root: Path, dry_run: bool = False):
        self.config = config
        self.root = root
        self.dry_run = dry_run
        schema_path = self.root / "config" / "skill_card_schema.json"
        with open(schema_path, "r", encoding="utf-8") as handle:
            self.schema = json.load(handle)
        self.validator = Draft7Validator(self.schema)
        self.deck_path = self.root / "storage" / "L3_SKILL_DECK"
        self.deck_path.mkdir(parents=True, exist_ok=True)

    def find_similar_skill(self, cluster: Dict) -> Optional[Dict]:
        module_path = self.deck_path / cluster.get("module", "common")
        if not module_path.exists():
            return None
        for card_file in module_path.glob("*.json"):
            with open(card_file, "r", encoding="utf-8") as handle:
                card = json.load(handle)
                if card.get("topic") == cluster.get("theme"):
                    card["_path"] = card_file
                    return card
        return None

    def create_skill(self, cluster: Dict) -> Dict:
        card = self._build_card(cluster)
        self._validate(card)
        if not self.dry_run:
            self._persist_card(card)
        return card

    def update_skill(self, existing: Dict, cluster: Dict) -> Dict:
        updated = self._build_card(cluster, existing_id=existing.get("id"))
        updated.setdefault("metadata", {})["deprecates"] = [existing.get("id")]
        self._validate(updated)
        if not self.dry_run:
            target_path = existing.get("_path") or self._build_path(updated)
            self._persist_card(updated, target_path)
        return updated

    def _build_card(self, cluster: Dict, existing_id: Optional[str] = None) -> Dict:
        module = cluster.get("module", "common")
        card_id = existing_id or self._generate_id(module, cluster.get("theme", "general"))
        now_iso = datetime.utcnow().isoformat() + "Z"
        episodes = cluster.get("episodes", [])
        evidence_refs = [ep.get("raw_refs", []) for ep in episodes]
        flattened_refs = [item for sublist in evidence_refs for item in (sublist or [])]

        card = {
            "$schema": "./schemas/skill_card_v2.json",
            "id": card_id,
            "version": "2.0",
            "module": module,
            "topic": cluster.get("theme", "general"),
            "created": now_iso,
            "last_updated": now_iso,
            "confidence": float(cluster.get("confidence", 0.5)),
            "rule": {
                "trigger": "Derived from latest semantic cluster",
                "action": "Summarize best-known mitigation and optimization steps",
                "expected_outcome": "Operational improvement based on synthesized experience",
            },
            "anti_rule": {
                "never_when": "Strategic experiments or trusted partner overrides",
                "reason": "Special cases may require separate evaluation",
            },
            "evidence": {
                "episode_count": len(episodes),
                "success_rate": float(cluster.get("confidence", 0.5)),
                "refs": flattened_refs[:10],
            },
            "metadata": {
                "impact_score": cluster.get("impact", 0.5),
                "usage_count": 0,
                "last_validated": now_iso,
                "tags": [cluster.get("theme", "general")],
            },
        }
        return card

    def _generate_id(self, module: str, theme: str) -> str:
        slug = theme.upper().replace(" ", "_")
        return f"SKILL:{module.upper()}:{slug}:001"

    def _validate(self, card: Dict) -> None:
        errors = sorted(self.validator.iter_errors(card), key=lambda e: e.path)
        if errors:
            raise ValueError("Skill card validation failed: " + "; ".join(err.message for err in errors))

    def _build_path(self, card: Dict) -> Path:
        module_dir = self.deck_path / card.get("module", "common")
        module_dir.mkdir(parents=True, exist_ok=True)
        filename = f"{card['id'].replace(':', '_')}.json"
        return module_dir / filename

    def _persist_card(self, card: Dict, path: Optional[Path] = None) -> None:
        target_path = path or self._build_path(card)
        target_path.parent.mkdir(parents=True, exist_ok=True)
        with open(target_path, "w", encoding="utf-8") as handle:
            json.dump(card, handle, indent=2)
        logger.info("Stored Skill Card at %s", target_path)

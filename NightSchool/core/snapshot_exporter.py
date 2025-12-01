"""
Snapshot exporter generates AI_SPEC_SNAPSHOT_v2 style artifacts.
"""

import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List

logger = logging.getLogger(__name__)


class SnapshotExporter:
    """Builds a compact snapshot from skill cards and statistics."""

    def __init__(self, config: Dict, root: Path, dry_run: bool = False):
        self.config = config
        self.root = root
        self.dry_run = dry_run
        self.deck_path = self.root / "storage" / "L3_SKILL_DECK"

    def create_snapshot(self, top_n: int = 30) -> Dict:
        skills = self._load_skills(top_n)
        snapshot = {
            "version": "AI_SPEC_SNAPSHOT_v2",
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "skill_cards": skills,
            "core_state": {
                "modules": self.config.get("modules", {}),
                "storage": self.config.get("storage", {}),
                "anthropic": self.config.get("anthropic", {}).get("models", {}),
            },
            "stats": {
                "skill_count": len(skills),
                "top_n": top_n,
                "size_tokens": self._estimate_tokens(skills),
            },
        }
        return snapshot

    def save_snapshot(self, snapshot: Dict, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(snapshot, handle, indent=2)
        logger.info("Saved snapshot to %s", path)

    def _load_skills(self, top_n: int) -> List[Dict]:
        skills: List[Dict] = []
        if not self.deck_path.exists():
            return skills
        for card_path in sorted(self.deck_path.rglob("*.json")):
            try:
                with open(card_path, "r", encoding="utf-8") as handle:
                    card = json.load(handle)
                    skills.append(card)
            except json.JSONDecodeError:  # pragma: no cover - skip corrupted cards
                continue
        # Sort by confidence descending
        skills.sort(key=lambda c: c.get("confidence", 0), reverse=True)
        return skills[:top_n]

    def _estimate_tokens(self, skills: List[Dict]) -> int:
        approx_chars = sum(len(json.dumps(skill)) for skill in skills)
        return int(approx_chars / 4)  # rough text token approximation

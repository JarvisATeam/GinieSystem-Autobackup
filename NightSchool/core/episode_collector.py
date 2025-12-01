"""
Episode Collector - Step 1 of Night School
Collects raw experiences and converts to structured episodes.
"""

import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict

from anthropic import Anthropic

logger = logging.getLogger(__name__)


class EpisodeCollector:
    """Collects and structures raw operational data into episodes."""

    def __init__(self, config: Dict, root: Path):
        self.config = config
        self.root = root
        self.client = Anthropic()
        self.l1_path = self.root / "storage" / "L1_RAW"
        self.l2_path = self.root / "storage" / "L2_SEMANTIC"
        self.l1_path.mkdir(parents=True, exist_ok=True)
        self.l2_path.mkdir(parents=True, exist_ok=True)

    def collect_from_module(self, module_name: str) -> List[Dict]:
        raw_logs = self._load_recent_logs(module_name)
        if not raw_logs:
            logger.warning("No logs found for %s", module_name)
            return []

        episodes = self._extract_episodes(module_name, raw_logs)
        return episodes

    def _load_recent_logs(self, module_name: str) -> List[Dict]:
        log_dir = self.l1_path / module_name
        if not log_dir.exists():
            return []

        cutoff = datetime.now() - timedelta(days=1)
        recent_logs = []
        for log_file in log_dir.glob("*.log"):
            if datetime.fromtimestamp(log_file.stat().st_mtime) > cutoff:
                with open(log_file, "r", encoding="utf-8") as handle:
                    recent_logs.append({"file": str(log_file), "content": handle.read()})
        return recent_logs

    def _extract_episodes(self, module_name: str, raw_logs: List[Dict]) -> List[Dict]:
        combined = "\n\n".join([f"=== {log['file']} ===\n{log['content']}" for log in raw_logs])
        max_log_chars = 50000
        if len(combined) > max_log_chars:
            combined = combined[:max_log_chars] + "\n\n[TRUNCATED]"

        prompt = f"""Extract structured learning episodes from these logs.

MODULE: {module_name}
LOGS:
{combined}

For each significant event (error, success, decision), create an episode with:
- situation: what triggered this
- action: what was done
- result: what happened
- timestamp: when it occurred
- raw_refs: references to log lines

OUTPUT: JSON array of episodes. Aim for 5-20 episodes max (focus on most significant).
"""

        try:
            response = self.client.messages.create(
                model=self.config["anthropic"]["models"].get("collector", "claude-sonnet-4.5"),
                max_tokens=4000,
                messages=[{"role": "user", "content": prompt}],
            )
            episodes_raw = response.content[0].text
            if "```json" in episodes_raw:
                episodes_raw = episodes_raw.split("```json")[1].split("```")[0]
            elif "```" in episodes_raw:
                episodes_raw = episodes_raw.split("```")[1].split("```")[0]

            episodes = json.loads(episodes_raw)
            now_iso = datetime.now().isoformat()
            for ep in episodes:
                ep.setdefault("module", module_name)
                ep.setdefault("collected_at", now_iso)
            return episodes
        except Exception as exc:  # pragma: no cover - defensive logging
            logger.error("Failed to extract episodes: %s", exc)
            return []

    def store_in_l2(self, episodes: List[Dict]) -> None:
        episodes_db = self.l2_path / "episodes.db"
        with open(episodes_db, "a", encoding="utf-8") as handle:
            for episode in episodes:
                handle.write(json.dumps(episode) + "\n")
        logger.info("Stored %s episodes in L2_SEMANTIC", len(episodes))

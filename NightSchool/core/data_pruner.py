"""
Data pruner applies TTL and pruning rules for Night School storage layers.
"""

import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict

logger = logging.getLogger(__name__)


class DataPruner:
    """Prune data in L1, L2, and L3 layers."""

    def __init__(self, config: Dict, root: Path, dry_run: bool = False):
        self.config = config
        self.root = root
        self.dry_run = dry_run
        self.l1_path = self.root / "storage" / "L1_RAW"
        self.l2_path = self.root / "storage" / "L2_SEMANTIC"
        self.l3_path = self.root / "storage" / "L3_SKILL_DECK"

    def prune_all_layers(self) -> Dict:
        total_bytes = 0
        total_bytes += self._prune_l1()
        total_bytes += self._prune_l2()
        total_bytes += self._prune_l3()
        return {"total_mb": total_bytes / (1024 * 1024)}

    def _prune_l1(self) -> int:
        ttl_days = self.config.get("storage", {}).get("L1_RAW", {}).get("ttl_days", 30)
        cutoff = datetime.now() - timedelta(days=ttl_days)
        return self._prune_folder(self.l1_path, cutoff)

    def _prune_l2(self) -> int:
        max_size_gb = self.config.get("storage", {}).get("L2_SEMANTIC", {}).get("max_episodes", 50000)
        # Placeholder: no direct file size cap; rely on TTL by default
        _ = max_size_gb
        cutoff = datetime.now() - timedelta(days=90)
        return self._prune_folder(self.l2_path, cutoff)

    def _prune_l3(self) -> int:
        archive_days = self.config.get("storage", {}).get("L3_SKILL_DECK", {}).get(
            "archive_unused_days", 60
        )
        cutoff = datetime.now() - timedelta(days=archive_days)
        return self._prune_folder(self.l3_path, cutoff, respect_suffix=".json")

    def _prune_folder(self, path: Path, cutoff: datetime, respect_suffix: str | None = None) -> int:
        if not path.exists():
            return 0
        freed_bytes = 0
        for file_path in path.rglob("*" if respect_suffix is None else respect_suffix):
            try:
                modified = datetime.fromtimestamp(file_path.stat().st_mtime)
                if modified < cutoff:
                    freed_bytes += file_path.stat().st_size
                    if not self.dry_run:
                        file_path.unlink()
            except FileNotFoundError:  # pragma: no cover - file might be removed in race
                continue
        if freed_bytes:
            logger.info("Pruned %.2f MB from %s", freed_bytes / (1024 * 1024), path)
        return freed_bytes

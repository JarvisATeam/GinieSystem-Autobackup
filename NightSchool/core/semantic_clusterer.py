"""
Semantic clusterer groups recent episodes into topic clusters.
"""

import logging
from collections import defaultdict
from pathlib import Path
from typing import Dict, List

import numpy as np

logger = logging.getLogger(__name__)


class SemanticClusterer:
    """Simple clustering placeholder that groups episodes by module and theme keywords."""

    def __init__(self, config: Dict, root: Path):
        self.config = config
        self.root = root
        self.threshold = self.config.get("storage", {}).get("L2_SEMANTIC", {}).get(
            "prune_threshold", 0.3
        )

    def cluster(self, episodes: List[Dict]) -> List[Dict]:
        clusters: List[Dict] = []
        grouped: Dict[str, List[Dict]] = defaultdict(list)
        for episode in episodes:
            key = episode.get("module", "common")
            grouped[key].append(episode)

        for module, module_eps in grouped.items():
            if not module_eps:
                continue
            confidence_scores = [ep.get("confidence", 0.5) for ep in module_eps]
            avg_conf = float(np.mean(confidence_scores)) if confidence_scores else 0.0
            theme = self._infer_theme(module_eps)
            clusters.append(
                {
                    "module": module,
                    "theme": theme,
                    "episodes": module_eps,
                    "confidence": avg_conf,
                }
            )
        return clusters

    def _infer_theme(self, episodes: List[Dict]) -> str:
        for episode in episodes:
            situation = episode.get("situation", "")
            if "roi" in situation.lower():
                return "roi_optimization"
            if "safety" in situation.lower():
                return "safety_guardrails"
        return episodes[0].get("module", "general") + "_general"

    def validate_clusters(self, clusters: List[Dict]) -> List[Dict]:
        valid = [c for c in clusters if c.get("confidence", 0.0) >= self.threshold]
        pruned = len(clusters) - len(valid)
        if pruned:
            logger.info("Pruned %s low-confidence clusters", pruned)
        return valid

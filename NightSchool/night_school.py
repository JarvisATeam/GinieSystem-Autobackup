#!/usr/bin/env python3
"""
Night School - Main Orchestrator
Implements NANOTECH_INTEL_MEMORY_v2 learning pipeline.
"""

import logging
import sys
from datetime import datetime
from pathlib import Path
import argparse
import yaml

from core.episode_collector import EpisodeCollector
from core.semantic_clusterer import SemanticClusterer
from core.skill_synthesizer import SkillSynthesizer
from core.data_pruner import DataPruner
from core.snapshot_exporter import SnapshotExporter

LOG_DIR = Path(__file__).resolve().parent / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / f"night_school_{datetime.now().strftime('%Y%m%d')}.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(__name__)


class NightSchool:
    """Main Night School orchestrator."""

    def __init__(self, config_path: str = "config/night_school.yaml", dry_run: bool = False):
        self.root = Path(__file__).resolve().parent
        self.config_path = self.root / config_path
        self.dry_run = dry_run

        logger.info("🌙 Initializing Night School...")
        with open(self.config_path, "r", encoding="utf-8") as f:
            self.config = yaml.safe_load(f)

        self.episode_collector = EpisodeCollector(self.config, root=self.root)
        self.clusterer = SemanticClusterer(self.config, root=self.root)
        self.synthesizer = SkillSynthesizer(self.config, root=self.root, dry_run=dry_run)
        self.pruner = DataPruner(self.config, root=self.root, dry_run=dry_run)
        self.exporter = SnapshotExporter(self.config, root=self.root, dry_run=dry_run)

        self.stats = {
            "start_time": datetime.now(),
            "episodes_collected": 0,
            "clusters_found": 0,
            "skills_created": 0,
            "skills_updated": 0,
            "data_pruned_mb": 0.0,
        }

    def run(self) -> bool:
        logger.info("=" * 60)
        logger.info("🎓 NIGHT SCHOOL SESSION STARTING")
        logger.info(f"Time: {self.stats['start_time']}")
        logger.info("=" * 60)

        try:
            episodes = self.step_1_collect_episodes()
            logger.info("✅ Collected %s episodes", len(episodes))

            clusters = self.step_2_cluster_episodes(episodes)
            logger.info("✅ Identified %s knowledge clusters", len(clusters))

            skills = self.step_3_synthesize_skills(clusters)
            logger.info("✅ Created/updated %s Skill Cards", len(skills))

            pruned_mb = self.step_4_prune_data()
            logger.info("✅ Freed %.1f MB of storage", pruned_mb)

            snapshot = self.step_5_export_snapshot()
            logger.info("✅ Snapshot tokens: %s", snapshot.get("size_tokens", 0))

            self.print_final_report()
            return True
        except Exception as exc:  # pragma: no cover - defensive logging
            logger.error("❌ Night School failed: %s", exc, exc_info=True)
            return False

    def step_1_collect_episodes(self):
        all_episodes = []
        for module in self.config["modules"].get("enabled", []):
            logger.info("  Collecting from %s...", module)
            try:
                episodes = self.episode_collector.collect_from_module(module)
                all_episodes.extend(episodes)
                logger.info("    → %s episodes", len(episodes))
            except Exception as exc:  # pragma: no cover - defensive logging
                logger.error("    ⚠️ Failed to collect from %s: %s", module, exc)

        if not self.dry_run:
            self.episode_collector.store_in_l2(all_episodes)

        self.stats["episodes_collected"] = len(all_episodes)
        return all_episodes

    def step_2_cluster_episodes(self, episodes):
        clusters = self.clusterer.cluster(episodes)
        validated_clusters = self.clusterer.validate_clusters(clusters)
        self.stats["clusters_found"] = len(validated_clusters)
        return validated_clusters

    def step_3_synthesize_skills(self, clusters):
        new_skills = []
        updated_skills = []
        for cluster in clusters:
            logger.info("  Processing cluster: %s", cluster.get("theme", "unknown"))
            try:
                existing = self.synthesizer.find_similar_skill(cluster)
                if existing:
                    updated = self.synthesizer.update_skill(existing, cluster)
                    updated_skills.append(updated)
                    logger.info("    ↻ Updated: %s", updated.get("id"))
                else:
                    created = self.synthesizer.create_skill(cluster)
                    new_skills.append(created)
                    logger.info("    ✨ Created: %s", created.get("id"))
            except Exception as exc:  # pragma: no cover - defensive logging
                logger.error("    ⚠️ Failed to synthesize skill: %s", exc)

        self.stats["skills_created"] = len(new_skills)
        self.stats["skills_updated"] = len(updated_skills)
        return new_skills + updated_skills

    def step_4_prune_data(self):
        pruned = self.pruner.prune_all_layers()
        self.stats["data_pruned_mb"] = pruned.get("total_mb", 0.0)
        return pruned.get("total_mb", 0.0)

    def step_5_export_snapshot(self):
        snapshot = self.exporter.create_snapshot(
            top_n=self.config["output"].get("top_n_skills", 30)
        )
        if not self.dry_run:
            snapshot_path = self.root / "snapshots" / f"snapshot_{datetime.now().strftime('%Y%m%d')}.json"
            self.exporter.save_snapshot(snapshot, snapshot_path)
        return snapshot

    def print_final_report(self):
        duration = (datetime.now() - self.stats["start_time"]).total_seconds() / 60
        logger.info("\n" + "=" * 60)
        logger.info("🎓 NIGHT SCHOOL SESSION COMPLETE")
        logger.info("=" * 60)
        logger.info("Duration: %.1f minutes", duration)
        logger.info("Episodes collected: %s", self.stats["episodes_collected"])
        logger.info("Clusters found: %s", self.stats["clusters_found"])
        logger.info("Skills created: %s", self.stats["skills_created"])
        logger.info("Skills updated: %s", self.stats["skills_updated"])
        logger.info("Storage freed: %.1f MB", self.stats["data_pruned_mb"])
        logger.info("=" * 60)
        logger.info("💤 System ready for next day of learning.")


def main():
    parser = argparse.ArgumentParser(description="Night School - Knowledge Synthesis System")
    parser.add_argument("--config", default="config/night_school.yaml", help="Config file")
    parser.add_argument("--dry-run", action="store_true", help="Simulate without changes")
    args = parser.parse_args()

    school = NightSchool(config_path=args.config, dry_run=args.dry_run)
    success = school.run()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

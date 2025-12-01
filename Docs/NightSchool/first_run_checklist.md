# Night School First Run Checklist

## Pre-flight
- [ ] `ANTHROPIC_API_KEY` set in environment
- [ ] `~/GinieSystem/NightSchool/` structure created
- [ ] Dependencies installed (`anthropic`, `pyyaml`, `faiss-cpu`, `jsonschema`)
- [ ] Config files reviewed and customized
- [ ] At least 24 hours of `L1_RAW` logs available

## Test Run (Manual)
```bash
cd ~/GinieSystem/NightSchool
python night_school.py --dry-run
python night_school.py
```

## Verify Outputs
- [ ] Check `logs/night_school_YYYYMMDD.log`
- [ ] Verify `L2_SEMANTIC/episodes.db` has entries
- [ ] Verify `L3_SKILL_DECK/` has skill cards
- [ ] Check `snapshots/snapshot_YYYYMMDD.json` size < 3k tokens
- [ ] Review first Skill Cards for quality

## Integration
- [ ] Test loading snapshot in external LLM conversation
- [ ] Verify Skill Cards are actionable
- [ ] Connect to GUARDIAN for validation
- [ ] Update module logging to ensure L1_RAW capture

## Monitoring (Week 1)
- [ ] Daily: Check Night School completion
- [ ] Check storage growth (should plateau after pruning)
- [ ] Validate Skill Card confidence scores
- [ ] Test retrieval: Ask system to use a skill

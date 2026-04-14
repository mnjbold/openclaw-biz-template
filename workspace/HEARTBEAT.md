# HEARTBEAT.md — Workspace Operating Checklist

## Self-Improving Agent Loop (AnalogAgent Pattern)

For each task:
1. **RETRIEVE** — Pull top 5 validated rules from `.learnings/LEARNINGS.md` relevant to this task type
2. **GENERATE** — Produce candidate solution using retrieved rules
3. **VALIDATE** — Run machine-checkable gates (tests pass, file exists, HTTP 200)
4. **CURATE** — If better approach found: `brv curate "rule: <what> — evidence: <why> — confidence: <0.7-1.0>"`
5. **UPDATE** — Append to playbook: `workspace/playbook/<category>.json`

## Standard Checks (Every Session)

1. Read SOUL.md, USER.md, and today's `memory/YYYY-MM-DD.md` before acting
2. Create `memory/YYYY-MM-DD.md` for today if missing
3. Check BOOTSTRAP.md status — keep trimmed once identity established
4. Verify USER.md stays within 4152 chars
5. Scan context for recurring intent → convert to cron/automation
6. Write all durable decisions immediately to files
7. Create cron/heartbeat for clearly requested recurring behavior
8. Check files/tools before answering — never answer from assumption
9. Refuse fake certainty, flattery, filler agreement
10. Distill bloated context → MEMORY.md
11. Review OPERATIONS.md for open items
12. Use owner's actual active hours ({{ACTIVE_HOURS_START}}–{{ACTIVE_HOURS_END}}) for timing
13. Review standing priorities in OPERATIONS.md
14. Interrupt rules: immediate only for revenue blockers, urgent/NDA, explicit approvals
15. Verification doctrine: configured ≠ running, logged ≠ succeeded

## Weekly Maintenance (Every Sunday)

- Curate last 7 daily notes into MEMORY.md
- Run `workspace/scripts/doctor.sh` — check all agent health
- Check cost tracker: `workspace/ops/cost-tracker.json`
- Review `.learnings/LEARNINGS.md` — promote to SOUL.md or AGENTS.md if broadly applicable
- Archive daily notes older than 30 days: `memory/archive/YYYY-MM/`
- Check cron jobs: `openclaw cron list` — any consecutive errors?

## Playbook Schema (Validated Rules Storage)

```json
{
  "task_type": "linkedin_post",
  "component": "ContentDesk",
  "trigger": "user requests social post",
  "rule": "Always research trending topics before writing — posts without research get <50 impressions",
  "anti_pattern": "Writing from general knowledge without checking what's being discussed today",
  "evidence": "3 posts with research averaged 400+ impressions; 3 without averaged 45",
  "confidence": 0.85,
  "source": "session 2026-03-15",
  "reusable": true
}
```

## Communication Rules (Critical — Crons Were Breaking on These)

- Telegram delivery target MUST be numeric chat ID: `{{TELEGRAM_CHAT_ID}}`
- NOT the bot username. NOT the channel name.
- Never send code blocks to Telegram — file paths or summaries only
- Never send more than 300 words in a Telegram message

# HEARTBEAT.md — {{AGENT_NAME}} (Main Agent)

## Core Checks (Run Every Session — No Exceptions)

1. Read SOUL.md, USER.md, and today's `memory/YYYY-MM-DD.md` before acting
2. Create `memory/YYYY-MM-DD.md` for today if it doesn't exist
3. Check BOOTSTRAP.md — if identity established, keep it trimmed (≤3 lines)
4. Verify USER.md stays within 4152 chars
5. Scan context for recurring intent → convert to cron/automation immediately
6. Write all durable decisions to files — never rely on chat memory
7. Review OPERATIONS.md open items and standing responsibilities
8. Use {{YOUR_NAME}}'s actual active rhythm ({{ACTIVE_HOURS_START}}–{{ACTIVE_HOURS_END}}) for timing decisions
9. Check file existence/tool availability before answering factual questions
10. Refuse fake certainty, flattery, filler agreement
11. Distill bloated context → MEMORY.md
12. Interruption rules: immediate only for revenue blockers, urgent/NDA, explicit approvals
13. Verification doctrine: configured ≠ running, logged ≠ succeeded
14. Never send code blocks to Telegram — file paths or summaries only

## Proactive Work (Do Without Being Asked)

- Review and organize memory files
- Check cron job health via `openclaw cron list`
- Verify agent configurations haven't drifted
- Run `workspace/scripts/doctor.sh` to catch issues
- Update MEMORY.md with key decisions from last 7 days
- Check for new LinkedIn draft to send for approval

## When to Reach Out to {{YOUR_NAME}}

**Immediately:**
- Revenue-blocking issue discovered
- Income opportunity >{{ALERT_THRESHOLD}} found
- Something requiring external action (email send, money move)
- Cron failures that need human intervention

**Next session:**
- Non-urgent blockers
- Recommendations for new automations
- Summary of what persona agent found overnight

## When to Stay Quiet (HEARTBEAT_OK)

- Nothing new since last check
- All systems healthy, no action needed
- Outside proactive ping window unless urgent

## Session End — Memory Write-Back (Mandatory Before Ending)

Append to `memory/YYYY-MM-DD.md`:
```
## Session End — [HH:MM local]
### Accomplished
- [bullet list, facts only]
### Blocked
- [what and why]
### New Discoveries
- [paths, configs, credentials, tools]
### Lessons
- [→ also append to .learnings/LEARNINGS.md]
```

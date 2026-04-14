# OPERATIONS.md — {{YOUR_COMPANY}} Operations Ledger

## Purpose

Durable record of recurring responsibilities, standing commitments, and systemized follow-through.
If something needs to happen repeatedly → put it here or convert it to a cron job.

## Capture Rules

When {{YOUR_NAME}} expresses any of these, record here or convert to cron:
- Recurring tasks
- Standing responsibilities
- Repeated reminders
- Things to monitor regularly
- Habits for the agent to enforce
- Promises about future follow-through

## Standing Rules

1. **Never rely on chat history** for recurring intent — convert to files or automation
2. **Push back on weak plans** — do not agree just to be pleasant
3. **Default to continuous execution** until blocked — don't create decision tax after scope is clear
4. **Validate path, runtime, boot, and primary flows** before reporting completion
5. **Cost discipline** — free models only; log any paid usage to `ops/cost-tracker.json`

## Active Standing Priorities

### Priority 1 — Daily Briefing Loop ({{BRIEFING_TIME}} {{YOUR_TIMEZONE}})

The 3-Agent Daily Loop runs every day:
- **MailTriage** → classify Gmail, write `ops/state/mailtriage-latest.json`
- **TaskBoard** → select 3 MITs (Revenue Blocker > Client > Product), write `ops/state/taskboard-latest.json`
- **OpsChief** → produce briefing `ops/briefings/YYYY-MM-DD-briefing.md` (max 300 words), send Telegram

### Priority 2 — LinkedIn Content Engine ({{LINKEDIN_TIME}} {{YOUR_TIMEZONE}}, Mon-Fri)

Research → angle → draft → Telegram approval → PostIz publish on reply "post"

### Priority 3 — Persona Agent Overnight (daily)

Morning report at {{PERSONA_REPORT_TIME}}: income tracker, opportunities found, needs approval

## Recurring Responsibilities

| Area | Responsibility | Mechanism | Status |
|------|---------------|-----------|--------|
| Memory hygiene | Prevent forgetting, context loss, stale bootstrap | HEARTBEAT + MEMORY.md + daily notes | Active |
| Recurring intent | Convert repeated user intent to automation | HEARTBEAT review + cron | Active |
| Schedule awareness | Respect owner's active hours in timing decisions | USER.md + HEARTBEAT | Active |
| LinkedIn posting | Research → draft → approve → post | Cron + PostIz | Active |
| Cost tracking | Log all paid API usage | ops/cost-tracker.json | Active |
| Agent health | Weekly doctor.sh run | Sunday cron | Active |

## Cron Jobs Registry

| Job | Schedule | Agent | Purpose |
|-----|----------|-------|---------|
| nightly-briefing | {{BRIEFING_TIME}} daily | main | 3-agent daily loop |
| linkedin-content | {{LINKEDIN_TIME}} Mon-Fri | main | LinkedIn content pipeline |
| opportunity-scan | {{SCAN_TIME}} daily | persona | Freelance/hackathon scan |
| persona-morning | {{PERSONA_REPORT_TIME}} daily | persona | Morning income report |
| learnings-capture | 05:00 daily | main | Error/learning distillation |
| memory-compact | 02:00 Sunday | main | Weekly memory curation |
| agent-doctor | 06:00 Sunday | main | Health check all agents |

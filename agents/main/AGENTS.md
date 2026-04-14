# AGENTS.md — Main Agent Workspace Rules

## Workspace Structure
```
workspace/
├── memory/              ← Daily session logs (YYYY-MM-DD.md)
├── .learnings/          ← LEARNINGS.md, ERRORS.md, FEATURE_REQUESTS.md
├── drafts/              ← LinkedIn drafts, content awaiting approval
├── reports/             ← Generated Excel, PDF, Word reports
├── ops/                 ← State files, briefings, pipeline outputs
│   ├── state/           ← mailtriage-latest.json, taskboard-latest.json
│   └── briefings/       ← YYYY-MM-DD-briefing.md
├── config/              ← postiz.json, google-workspace.json
├── scripts/             ← postiz-post.sh, doctor.sh, cost-tracker.sh
└── templates/           ← Reusable document templates
```

## Sub-Agent Spawn Rules

**When to spawn:**
- Task requires >2 files to change simultaneously
- Research needed (use ResearchDesk or a browser-enabled sub-agent)
- Multi-domain work (spawn parallel desks via CoWork Director)
- Session at turn 12+ → write handoff, spawn fresh continuation

**When NOT to spawn:**
- Quick answers (just respond)
- Single-file edits
- Simple status checks

**Spawn limits:** maxConcurrent 4, maxDepth 2, maxChildren 3, archive after 30min

## Communication Rules

**Telegram/Google Chat (never):**
- No raw code blocks
- No full file contents
- No raw JSON dumps
- Use: file paths, bullet summaries, key numbers

**File naming:**
- Reports: `workspace/reports/YYYY-MM-DD-<topic>.md`
- Drafts: `workspace/drafts/<type>-YYYY-MM-DD.md`
- Briefings: `workspace/ops/briefings/YYYY-MM-DD-briefing.md`

## Memory Discipline

Write to files, not mental notes. Files survive restarts.

| What | Where | When |
|------|-------|------|
| Today's work | `memory/YYYY-MM-DD.md` | End of session |
| Long-term insights | `MEMORY.md` | Weekly curation |
| Errors & corrections | `.learnings/ERRORS.md` | Immediately |
| Patterns & rules | `.learnings/LEARNINGS.md` | When discovered |
| Durable context | ByteRover (`brv curate`) | For cross-session rules |

## NDA Isolation Rules

- If task mentions employer/client data → route to `bold-ops` immediately
- No employer data in `workspace/` — only in `workspace/employer/` (bold-ops territory)
- `bold-ops` channel: Google Chat (not Telegram)
- Never reference bold-ops workspace from main workspace files

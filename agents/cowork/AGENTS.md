# AGENTS.md — CoWork Director

## CoWork Team Structure

```
CoWork Director (kimi-k2.5)
├── OpsDesk (minimax-m2.5)     ← Email, calendar, tasks, briefings
├── ContentDesk (glm-5)        ← LinkedIn, blog, docs, slides, copy
├── DataDesk (minimax-m2.5)    ← Excel, PDF, reports, analytics
├── CodeDesk (kimi-k2.5)       ← Code, GitHub, automation, bugs
├── ResearchDesk (glm-5)       ← Market research, competitors, search
└── MemoryDesk (minimax-m2.5)  ← Memory, learnings, knowledge capture
```

## How to Route

1. Parse the request → identify primary domain
2. For single-domain → spawn that desk, return result
3. For multi-domain → decompose → spawn desks in parallel → consolidate
4. For ambiguous → default OpsDesk (ops context) or ResearchDesk (unknowns)
5. Never block — if a desk fails, report and continue

## Sub-Agent Spawn Commands

```
# Spawn a specific desk
/subagents spawn ops-desk "Read Gmail, classify urgent items"
/subagents spawn content-desk "Write LinkedIn post about AI agents"
/subagents spawn code-desk "Fix the authentication bug in app/auth.py"

# Parallel multi-desk task
/subagents spawn ops-desk "Get this week's meetings" &
/subagents spawn research-desk "Find competitors in the AI SaaS space" &
```

## Output Format

All desk outputs saved to:
`workspace/cowork/outputs/YYYY-MM-DD/<desk-name>-<task-id>.md`

## Rate Limits

Max 3 desks parallel per request.
Each desk: max 10min timeout, max 800 tokens system prompt.
After 30min idle: archive desk session.

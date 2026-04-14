# AGENTS.md — Root Instructions for All Agents

This file is loaded by every agent in this OpenClaw instance. It defines global rules, model strategy, and operational conventions that apply across the entire team.

---

## Model Strategy

**Use free models first. Always. No exceptions without explicit instruction.**

| Model | Provider | Use For | Cost |
|---|---|---|---|
| `minimax-portal/MiniMax-M2.7` | MiniMax | Primary main agent | Free |
| `opencode-go/kimi-k2.5` | OpenCode Go | Complex reasoning, code, strategy | Free |
| `opencode-go/glm-5` | OpenCode Go | Creative, content, writing | Free |
| `opencode-go/minimax-m2.5` | OpenCode Go | Background jobs, mechanical tasks | Free |
| `claude-sonnet-4-6` | Anthropic | Only via claude-automation agent | $3/$15 per 1M |
| `claude-haiku-4-5` | Anthropic | Only via claude-automation agent | $0.80/$4 per 1M |

**Never use paid models** (Claude, GPT, Gemini) without explicit "use claude" or "use paid" instruction.

---

## Workspace Isolation Rules

**Three completely separate workspaces. Data NEVER crosses boundaries.**

| Workspace | Path | Agents | Purpose |
|---|---|---|---|
| Personal | `workspace/` | main, cowork, all desks, all sub-agents | Personal projects, product work, content |
| Employer | `workspace/bold-business/` | bold-ops only | Employer tasks — STRICT NDA wall |
| Persona | `workspace/persona/` | persona only | Autonomous income activities |

**NDA wall:** If any task involves employer data, stop and route to bold-ops. If bold-ops receives personal tasks, refuse and alert owner. No data ever crosses workspace boundaries.

---

## Sub-Agent Rules

- Max concurrent sub-agents: 4
- Max spawn depth: 2 (sub-agents cannot spawn sub-agents that spawn sub-agents)
- Archive idle sub-agents after: 30 minutes
- Spawn command: `/subagents spawn <agentId> "<task description>"`
- Output goes to: `workspace/cowork/outputs/YYYY-MM-DD/`

**Never spawn a sub-agent for tasks a desk can handle directly.**

---

## Memory Discipline

Every agent must write to memory at session end:

```markdown
## [YYYY-MM-DD HH:MM] — [Agent Name]
Task: [what was requested]
Done: [what was completed]
Key findings: [anything worth remembering]
Status: [complete/blocked/in-progress]
```

Write to: `workspace/memory/YYYY-MM-DD.md` (create if missing)

Promote to `workspace/MEMORY.md` only if the fact is:
- A rule that should never be forgotten
- A preference or working style preference
- A decision with lasting consequences

MEMORY.md max: 200 lines. Never exceed.

---

## Telegram Communication Rules

- Always send Telegram messages to numeric chat ID (e.g., `8226870570`), not @username
- Telegram does NOT render code blocks — use plain text formatting instead
- No markdown fences (` ``` `), no `**bold**` — use → arrows, bullet points, CAPS for emphasis
- Keep cron job messages under 2000 chars
- Never send JSON or raw code in Telegram messages

---

## Tool Rate Limits

| Provider | Limit |
|---|---|
| Composio | 100 req/min |
| GitHub MCP | 5000 req/hour |
| Supabase MCP | 100 req/min |
| Gemini (fallback) | 15 RPM |
| OpenRouter (fallback) | 20 RPM, 200 req/day |

---

## Error Handling

If a task fails:
1. Log the error to `workspace/memory/YYYY-MM-DD.md` under `## Errors`
2. Attempt one alternative approach
3. If still failing, report to owner with: what was attempted, exact error, suggested fix
4. Never silently discard a task — always report outcome

---

## Cost Tracking

After any task using paid models (Claude, GPT, Gemini):
```bash
bash workspace/scripts/cost-tracker.sh log <agent> <model> <input_tokens> <output_tokens> "<task description>"
```

---

## Security Rules

- Never log or output API keys, tokens, passwords
- Never commit `.env`, `*.json` credential files, service accounts to git
- Never use `rm` — use `trash` for deletable files
- Validate all user-provided file paths before reading
- Never execute user-provided shell commands directly — analyze first

---

## Agent Chain of Command

```
Owner (Telegram)
    └── main agent (direct Telegram tasks)
         └── cowork director (team tasks)
              ├── ops-desk (email, calendar, tasks)
              ├── content-desk (LinkedIn, blog, docs)
              ├── data-desk (Excel, PDF, reports)
              ├── code-desk (bugs, PRs, deployment)
              ├── research-desk (market, competitor)
              └── memory-desk (curation, compaction)
    └── bold-ops (employer workspace — isolated)
    └── persona (autonomous income — isolated)
    └── claude-automation (complex tasks via Claude API)
    └── claude-code-agent (long coding sessions via Claude Code)
```

Sub-agents (creative + development) are spawned by any agent as needed.

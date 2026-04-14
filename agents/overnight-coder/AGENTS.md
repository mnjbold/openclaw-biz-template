# AGENTS.md — Sentinel Workspace Rules

## Workspace Access

**In scope (read + write):**
- `/root/.openclaw/agents/overnight-coder/` — own workspace
- All project repositories in scope (see SOUL.md Active Codebases)
- `workspace/ops/briefings/` — for morning reports

**Out of scope (never touch):**
- `workspace/bold-business/` — NDA-isolated
- `workspace/mrbijou/` or persona workspace — not coding territory
- `workspace/drafts/` — content team territory

## Sub-Agent Rules

When spawning worker sub-agents for code tasks:
- Use `glm-5` for boilerplate, docs, test scaffolding
- Use `kimi-k2.5` (via code-desk) only for complex logic
- Max 3 concurrent workers
- Each worker: max 5 files, max 800 tokens system context

## Commit Discipline

```
[sentinel] fix: <specific issue fixed>
[sentinel] feat: <feature added per issue #X>
[sentinel] test: <test coverage added for X>
[sentinel] refactor: <why refactored, what improved>
```

Always include: what was changed AND why.

## Communication Rules

- Never send code to Telegram — file path only
- Morning report = file path only in Telegram message
- If blocked: create GitHub issue with full context, then move on
- If urgent: Telegram message + issue link, not full explanation

## Red Lines

- Never push to main/master
- Never modify .env or credentials files
- Never touch Bold Business codebase (NDA wall)
- Never deploy to production without explicit approval in writing

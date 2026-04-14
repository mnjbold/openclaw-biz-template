# MEMORY.md — {{YOUR_COMPANY}} Operations

Last updated: {{SETUP_DATE}}

## Active Rules & Patterns

- Free models only — `kimi-k2.5` (complex), `glm-5` (creative), `minimax-m2.5` (cron/background). Never use paid without explicit approval.
- Verification doctrine: configured ≠ running, logged ≠ succeeded — always verify
- Telegram delivery must use numeric chat ID `{{TELEGRAM_CHAT_ID}}`, not bot username
- NDA wall: employer/client data → bold-ops workspace only. Never enters main workspace.
- PostIz LinkedIn automation: draft to `workspace/drafts/linkedin-YYYY-MM-DD.md` with YAML frontmatter → Telegram approval → `bash workspace/scripts/postiz-post.sh <draft> <target>`

## Key Configurations

- Composio API: configured in `config/mcporter.json`
- PostIz API: `workspace/config/postiz.json` (fill API key + channel IDs)
- Google Workspace: `workspace/config/google-workspace.json` + `docs/GOOGLE-WORKSPACE.md`

## Open Questions

_(add questions here as they arise)_

## Agent Team

| Agent | Model | Channel | Status |
|-------|-------|---------|--------|
| main ({{AGENT_NAME}}) | kimi-k2.5 | Telegram | Active |
| cowork | kimi-k2.5 | Telegram | Active |
| bold-ops | kimi-k2.5 | Google Chat | Active |
| persona ({{PERSONA_NAME}}) | kimi-k2.5 | Telegram | Active |
| claude-automation | claude-sonnet-4-6 | Telegram | On-demand |
| claude-code-agent | Claude Code CLI | Local | On-demand |

# TOOLS.md — {{AGENT_NAME}}

## Environment (Verify After Install)
```bash
node --version         # Target: v24+
python3 --version      # Target: 3.10+
git --version          # Target: 2.40+
gh --version           # Target: 2.80+ (GitHub CLI)
openclaw --version     # Target: 2026+
mcporter --version     # Target: 0.8+
brv --version          # ByteRover CLI
```

## Model Routing (Free Only — Never Use Paid Without Approval)

### Primary — OpenCode Go (Nebius Token Factory)
| Model | Alias | Use For | Priority |
|-------|-------|---------|----------|
| `opencode-go/kimi-k2.5` | Kimi | Complex reasoning, coding, strategy | 1st |
| `opencode-go/glm-5` | GLM | Creative text, content generation | 2nd |
| `opencode-go/minimax-m2.5` | MiniMax | Cron jobs, automation, summaries | 3rd |

### Fallback — Free Tier (Rate Limit Aware)
| Model | Rate Limit | Use For |
|-------|-----------|---------|
| Gemini free | 15 RPM, 1M tokens/day | Heavy reasoning |
| `openrouter/free` | 20 RPM, 200 req/day | Auto-router across free models |
| `qwen/qwen3-coder:free` | 20 RPM, 200 req/day | Coding overflow |

### Rate Limit Rules
1. OpenCode Go primary — not rate-limited, use freely
2. Never exceed 20 req/min on OpenRouter
3. Batch similar tasks into single calls
4. Add 3–5s delay between consecutive free model calls
5. If 429 error → wait 60s → retry with different model
6. Track daily usage — OpenRouter resets at midnight UTC

## MCP Servers (via mcporter)
```bash
mcporter config list              # List configured servers
mcporter call <server> <tool>     # Call an MCP tool
```

| Server | Use For |
|--------|---------|
| composio | Gmail, Drive, Calendar, LinkedIn, GitHub, Sheets |
| supabase | Database, storage, edge functions |
| github | GitHub API (if not using gh CLI) |
| Context7 | Live documentation lookup |
| Playwright | Browser automation |

## ByteRover (Persistent Context)
```bash
brv curate "insight to save"      # Save to context tree
brv space list                    # List knowledge spaces
```

## Key CLI Tools
```bash
gh pr create --title "..." --body "..." # Create GitHub PR
gh issue create --title "..." --body "..."
firebase deploy                    # Firebase deploy
mcporter call composio execute --action GMAIL_FETCH_EMAILS --params '{}'
```

## Skills (Read Before Specialized Work)
| Task | Skill File |
|------|-----------|
| Excel/spreadsheet | `/root/.openclaw/skills/excel-xlsx-*/SKILL.md` |
| Word documents | `/root/.openclaw/skills/word-docx-*/SKILL.md` |
| PDF editing | `/root/.openclaw/skills/nano-pdf-*/SKILL.md` |
| GitHub workflows | `/root/.openclaw/skills/github-*/SKILL.md` |
| n8n automation | `/root/.openclaw/skills/n8n-workflow-automation-*/SKILL.md` |
| Marketing/content | `/root/.openclaw/skills/marketing-skills-*/SKILL.md` |
| Agent autonomy | `/root/.openclaw/skills/agent-autonomy-kit-*/SKILL.md` |

Read each skill ONCE per session. Do not re-read.

## Rules
- Always verify tool availability before claiming capability
- Use cheapest model that gets the job done
- Never hallucinate data or fake success when access unavailable
- Write to files, not mental notes
- Respect rate limits — batch requests, add delays

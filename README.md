# OpenClaw Business Team Template

**Get your entire AI agent team running in under 1 hour.**

This template gives you a production-ready OpenClaw workspace with 35+ agents, automated workflows, LinkedIn content engine, Google Workspace integration, cost tracking, health monitoring, and a web-based installer — all pre-configured and ready to customize.

---

## What You Get

| Category | What's Included |
|---|---|
| **Agents** | 6 core agents + 6 CoWork desks + 27 specialist sub-agents |
| **Content Engine** | Daily LinkedIn drafts → Telegram approval → PostIz publish |
| **Automation** | Claude API agent + Claude Code agent for real engineering tasks |
| **Google Workspace** | Gmail, Drive, Calendar for entire team via 1 service account |
| **Memory System** | 4-level memory hierarchy — agents never forget |
| **Cost Tracking** | Per-agent, per-model, per-task cost metrics with daily/monthly limits |
| **Health Monitor** | Doctor script — checks every component weekly |
| **Installer** | Web UI wizard (port 8181) + CLI setup script |

---

## Prerequisites

- VPS or WSL2 on Windows (Ubuntu 20.04+ recommended)
- [OpenClaw](https://openclaw.ai) installed (`npm install -g openclaw`)
- Node.js ≥ 18, Python 3.8+
- A Telegram bot token ([get one from @BotFather](https://t.me/BotFather))
- API keys (details in Step 3)

---

## Quick Start — 1 Hour Setup

### Step 0 — Clone This Template

```bash
git clone https://github.com/W3JDev/openclaw-biz-template ~/.openclaw
cd ~/.openclaw
```

If you already have an OpenClaw installation, clone to a staging directory first and copy files selectively.

---

### Step 1 — Run the Web Installer (Recommended)

```bash
pip3 install fastapi uvicorn
python3 installer/app.py
```

Open your browser to `http://localhost:8181`

The installer walks you through 7 steps:
1. **Identity** — your name, company, timezone
2. **Telegram** — bot token, chat ID (auto-detected)
3. **API Keys** — OpenCode Go, Composio, PostIz, Supabase, Anthropic
4. **Employer Workspace** — if you manage a separate team (e.g., Bold Business)
5. **Models** — primary and fallback model selection
6. **Review** — preview your full config before applying
7. **Install** — generates `openclaw.json` and starts the daemon

**Or use the CLI setup script:**

```bash
bash setup.sh
```

---

### Step 2 — Personalize Your Agents

After the installer runs, update these files with your details:

**Your main agent identity (`agents/main/SOUL.md`):**
- Replace all `{{YOUR_NAME}}`, `{{YOUR_COMPANY}}`, `{{AGENT_NAME}}` placeholders
- Customize the missions section for your actual priorities
- Add your LinkedIn profile URL and PostIz channel IDs

**Your user profile (`agents/main/USER.md`):**
- Fill in your name, role, email, timezone, working hours, communication style

**Workspace operations (`workspace/OPERATIONS.md`):**
- Update the standing priorities to match your actual work
- Customize the recurring responsibilities table

---

### Step 3 — Get Your API Keys

| Service | Where to Get | Used For |
|---|---|---|
| **OpenCode Go** | [app.opencode.go](https://opencode.go) → API Keys | Free models (kimi-k2.5, glm-5, minimax-m2.5) |
| **Composio** | [app.composio.dev](https://app.composio.dev) → API Keys | Gmail, Drive, Calendar, LinkedIn, GitHub |
| **PostIz** | [app.postiz.com](https://app.postiz.com) → Settings → API | LinkedIn auto-posting |
| **Supabase** | [app.supabase.com](https://app.supabase.com) → Project → Settings | Database for your agents |
| **Anthropic** | [console.anthropic.com](https://console.anthropic.com) | Claude automation agent (optional, paid) |

Add them to `openclaw.json` or `.env`:

```bash
cp .env.example .env
# Edit .env with your keys
```

---

### Step 4 — Configure Telegram

Your main agent receives tasks via Telegram. You need:

1. **Bot token** — from @BotFather (`/newbot`)
2. **Your chat ID** — message your bot, then visit:
   `https://api.telegram.org/bot<TOKEN>/getUpdates`
   Find `"id"` under `"chat"` in the response

Update `openclaw.json`:
```json
"channels": {
  "telegram": {
    "token": "YOUR_BOT_TOKEN_HERE",
    "allowed_users": ["YOUR_CHAT_ID"]
  }
}
```

---

### Step 5 — Set Up Google Workspace (Optional)

If your team uses Google Workspace (Gmail, Drive, Calendar):

```bash
# Any team member runs this — Windows, Mac, Linux, or WSL:
npx bb-workspace-setup
# or:
npx bb-workspace
```

This walks you through:
1. Creating a Google Cloud service account
2. Enabling domain-wide delegation
3. Testing Gmail access for all team members
4. Writing the config to `~/.openclaw/config/google-workspace.json`

Manual setup is in `docs/GOOGLE-WORKSPACE.md`.

---

### Step 6 — Configure PostIz LinkedIn Posting

1. Get your PostIz API key from [app.postiz.com](https://app.postiz.com)
2. Connect your LinkedIn account(s) in PostIz
3. Get the channel IDs from PostIz → Channels
4. Update `workspace/config/postiz.json`:

```json
{
  "apiKey": "YOUR_POSTIZ_API_KEY",
  "baseUrl": "https://api.postiz.com/public/v1",
  "channels": {
    "personal": "YOUR_LINKEDIN_PERSONAL_CHANNEL_ID",
    "bijou": "YOUR_LINKEDIN_BRAND_CHANNEL_ID"
  }
}
```

---

### Step 7 — Start OpenClaw

```bash
openclaw start
openclaw status     # verify all agents are running
openclaw cron list  # verify scheduled jobs
```

Send a message to your Telegram bot to test the main agent.

---

### Step 8 — Run Health Check

```bash
bash workspace/scripts/doctor.sh
```

This verifies all tools, agents, cron jobs, memory files, and configs. Fix any reported failures before going live.

---

## Agent Directory

### Core Agents

| Agent | Model | Channel | Purpose |
|---|---|---|---|
| `main` | MiniMax M2.7 | Telegram | Primary assistant — ops, ops, memory |
| `cowork` | kimi-k2.5 | Telegram | Routes tasks to 6 specialist desks |
| `bold-ops` | kimi-k2.5 | Google Chat | Isolated employer workspace agent |
| `persona` | glm-5 | Autonomous | Your digital twin — income + brand |
| `claude-automation` | claude-sonnet-4-6 | Sub-agent | Complex multi-step tasks via Claude API |
| `claude-code-agent` | Claude Code CLI | Sub-agent | Long-running coding sessions (30–60 min) |

### CoWork Desks (routed via `cowork`)

| Desk | Model | Handles |
|---|---|---|
| `ops-desk` | minimax-m2.5 | Email triage, calendar, tasks, scheduling |
| `content-desk` | glm-5 | LinkedIn, blog posts, docs, slides |
| `data-desk` | minimax-m2.5 | Excel, PDFs, reports, Supabase queries |
| `code-desk` | kimi-k2.5 | Bugs, PRs, deployment, automation scripts |
| `research-desk` | glm-5 | Market research, competitor analysis |
| `memory-desk` | minimax-m2.5 | Memory curation, weekly compaction |

### Creative Sub-Agents (spawn via `/subagents spawn <id> "task"`)

| Agent ID | What It Does |
|---|---|
| `ad-copywriter` | Performance ads for LinkedIn/Meta/Google |
| `brand-designer` | Brand voice, style guides, visual direction |
| `copywriter` | Long-form sales copy, landing pages |
| `proofreader` | Grammar, tone, consistency checks |
| `ux-researcher` | User interviews, personas, journey maps |
| `storyboard-writer` | Video/reel storyboards |
| `video-scripter` | YouTube and short-form scripts |
| `podcast-producer` | Episode outlines, show notes, titles |
| `audio-producer` | Audio scripts, podcast production notes |
| `thumbnail-designer` | Thumbnail copy and direction briefs |

### Development Sub-Agents

| Agent ID | What It Does |
|---|---|
| `bug-hunter` | Root cause analysis, reproduction steps |
| `code-reviewer` | PR review, security, performance checks |
| `test-writer` | Unit/integration/e2e test generation |
| `qa-tester` | QA checklists, regression testing |
| `github-pr-reviewer` | GitHub PR automated review |
| `github-issue-triager` | Issue labeling, assignment, prioritization |
| `pr-merger` | Safe PR merge with checks |
| `api-documentation` | OpenAPI/Swagger docs generation |
| `api-tester` | API endpoint testing |
| `schema-designer` | Database schema, ERD design |
| `script-builder` | Bash/Python automation scripts |
| `migration-helper` | Database migration generation |
| `dependency-scanner` | Security vulnerabilities in deps |
| `changelog` | Release notes from git commits |
| `blockchain-analyst` | Smart contract analysis |
| `ecommerce-dev` | Store setup, product management |
| `game-designer` | Game mechanics, level design docs |

---

## Talking to Your Agent

Once Telegram is connected, message your bot:

| Command | What Happens |
|---|---|
| Any task | Main agent handles it |
| `@cowork [task]` | Routes to CoWork team |
| `post` | Posts latest LinkedIn draft to personal |
| `post bijou` | Posts to brand LinkedIn |
| `post both` | Posts to both |
| `edit: [feedback]` | Revises draft, re-sends for approval |
| `skip` | Discards draft, skips today |
| `/subagents spawn bug-hunter "fix the login error"` | Spawns specialist sub-agent |

---

## LinkedIn Content Engine

The automated LinkedIn pipeline runs daily:

```
09:00 MYT  →  content-desk drafts post  →  saves to workspace/drafts/
             →  Telegram: "Review your LinkedIn post for today:"
             →  You reply: post | post bijou | post both | edit: ... | skip
             →  PostIz API publishes immediately
             →  Confirmation sent to Telegram
```

Draft format (saved to `workspace/drafts/linkedin-YYYY-MM-DD.md`):
```yaml
---
date: 2026-04-15
target: personal
status: pending
---

Your post text here...

---
MEDIA BRIEF:
- Visual direction line 1
- Visual direction line 2
- Visual direction line 3
```

Manual posting: `bash workspace/scripts/postiz-post.sh workspace/drafts/linkedin-2026-04-15.md personal`

---

## Memory System

Your agents use a 4-level memory hierarchy so nothing is forgotten:

| Level | Location | What's Stored | When Written |
|---|---|---|---|
| **Daily notes** | `workspace/memory/YYYY-MM-DD.md` | Session events, decisions | Every session |
| **Long-term** | `workspace/MEMORY.md` | Curated facts, active rules | Weekly compaction |
| **Learnings** | `workspace/.learnings/LEARNINGS.md` | Reusable lessons, anti-patterns | When patterns emerge |
| **Context tree** | ByteRover (`brv`) | Cross-restart indexed knowledge | `brv curate "..."` |

Memory is automatically curated every Sunday at 02:00.

---

## Cost Tracking

Track AI spend per agent, model, and task:

```bash
# Initialize (auto-created on first use)
bash workspace/scripts/cost-tracker.sh init

# Log a session manually
bash workspace/scripts/cost-tracker.sh log bold-ops kimi-k2.5 5000 1000 "meeting notes"

# View cost report
bash workspace/scripts/cost-tracker.sh report

# Reset all data
bash workspace/scripts/cost-tracker.sh reset
```

Daily warning threshold: $5. Monthly warning: $50. Edit limits in `workspace/ops/cost-tracker.json`.

**Model costs (per 1M tokens):**
| Model | Input | Output |
|---|---|---|
| kimi-k2.5, glm-5, minimax-m2.5 | $0.00 | $0.00 |
| claude-haiku-4-5 | $0.80 | $4.00 |
| claude-sonnet-4-6 | $3.00 | $15.00 |
| claude-opus-4-6 | $15.00 | $75.00 |
| gemini-2.5-flash | $0.15 | $0.60 |

---

## Health Check

Run weekly or on-demand:

```bash
bash workspace/scripts/doctor.sh
```

Checks: tools installed, OpenClaw daemon, agent registration, SOUL.md files, cron job errors, memory files, PostIz config, openclaw.json placeholders, MCP servers, cost tracker.

Set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` env vars to receive failure alerts via Telegram.

---

## Scheduled Jobs (Cron)

All times in your local timezone (set in `openclaw.json` → `cron.timezone`).

| Job | Schedule | Agent | Purpose |
|---|---|---|---|
| Nightly Briefing | 22:00 daily | main | Daily ops summary to Telegram |
| Business Opening | 08:00 Mon–Fri | main | Morning priorities brief |
| LinkedIn Daily Post | 09:00 Mon–Fri | cowork | Draft + send for approval |
| Daily Memory Curator | 23:00 daily | main | Compress and curate memory |
| Weekly Memory Compaction | 02:00 Sunday | main | Full MEMORY.md curation |
| Agent Doctor | 06:00 Sunday | main | Health check report |
| Cost Report | 09:00 Monday | main | Weekly cost summary |

Edit schedules in `cron/jobs.template.json` before applying.

---

## Customization Guide

### Add a New Agent

1. Create `agents/<name>/SOUL.md` (use `agents/_template/HEARTBEAT.md` as reference)
2. Register in `openclaw.json` → `agents.list`
3. Run `openclaw restart`
4. Verify: `openclaw agents list | grep <name>`

### Add a New Cron Job

Add to `cron/jobs.template.json`:
```json
{
  "id": "unique-job-id",
  "name": "Job Name",
  "enabled": true,
  "schedule": "0 9 * * 1-5",
  "agent": "main",
  "sessionTarget": "isolated",
  "timeoutSeconds": 300,
  "payload": {
    "model": "opencode-go/minimax-m2.5",
    "message": "Your task prompt here"
  },
  "delivery": {
    "type": "announce",
    "channel": "telegram",
    "target": "YOUR_CHAT_ID"
  }
}
```

### Configure the Employer Agent (`bold-ops`)

If you work for an employer and want an isolated agent for that context:

1. Fill in `agents/bold-ops/SOUL.md` placeholders: `{{EMPLOYER_NAME}}`, `{{EMPLOYER_WORKSPACE_PATH}}`
2. Register Google Chat webhook if using Google Chat
3. Set workspace path to a completely separate directory
4. The bold-ops agent NEVER touches your personal workspace

---

## Skills

Pre-installed skills in `skills/`. See `skills/INSTALL.md` for how to install more from [clawhub.ai](https://clawhub.ai).

| Skill | Purpose |
|---|---|
| `word-docx` | Generate Word documents |
| `excel-xlsx` | Generate Excel spreadsheets |
| `powerpoint-pptx` | Generate PowerPoint presentations |
| `nano-pdf` | Edit and create PDFs |
| `data-analysis` | Data analysis workflows |
| `github` | GitHub PR/issue workflows |
| `marketing-skills` | LinkedIn/content copywriting |
| `superdesign` | UI/UX design generation |
| `memory-setup` | Memory system bootstrapping |
| `agent-autonomy-kit` | Agent self-improvement patterns |

---

## Directory Structure

```
~/.openclaw/
├── openclaw.json              # Master config — edit this to wire everything
├── AGENTS.md                  # Root instructions for all agents
├── cron/
│   └── jobs.json              # All scheduled tasks
├── config/
│   ├── mcporter.json          # MCP server definitions
│   ├── postiz.json            # PostIz API config (in workspace/config/)
│   └── google-workspace.json  # Google service account config
├── agents/
│   ├── main/                  # Primary agent (SOUL, HEARTBEAT, USER, IDENTITY, AGENTS, BOOTSTRAP)
│   ├── cowork/                # Team router (SOUL, ROUTING, AGENTS)
│   │   └── desks/             # 6 specialist desks (each with SOUL.md)
│   ├── bold-ops/              # Employer-isolated agent
│   ├── persona/               # Autonomous income/brand agent
│   ├── claude-automation/     # Claude API powered agent
│   ├── claude-code-agent/     # Claude Code CLI agent
│   ├── creative/              # 10 creative sub-agents
│   └── development/           # 17 development sub-agents
├── workspace/
│   ├── SOUL.md                # Workspace identity and Telegram command reference
│   ├── HEARTBEAT.md           # Self-improving agent loop
│   ├── MEMORY.md              # Long-term curated knowledge
│   ├── OPERATIONS.md          # Standing priorities and responsibilities
│   ├── memory/                # Daily session notes (YYYY-MM-DD.md)
│   ├── drafts/                # LinkedIn drafts (linkedin-YYYY-MM-DD.md)
│   ├── outputs/               # Sub-agent outputs
│   ├── logs/                  # Operation logs
│   ├── ops/                   # Cost tracker, doctor reports
│   ├── config/
│   │   └── postiz.json        # PostIz API config
│   └── scripts/
│       ├── postiz-post.sh     # LinkedIn posting script
│       ├── doctor.sh          # Health check
│       └── cost-tracker.sh    # Cost tracking
├── skills/                    # Installed skill packages
├── gworkspace-setup/          # npx bb-workspace npm package
└── installer/
    └── app.py                 # Web UI installer (FastAPI, port 8181)
```

---

## Troubleshooting

**Agent not responding in Telegram:**
- Check: `openclaw status`
- Verify bot token and chat ID in `openclaw.json`
- Restart: `openclaw restart`

**Cron job not running:**
- Check: `openclaw cron list` — look for `consecutiveErrors`
- Verify timezone in `openclaw.json` → `cron.timezone`
- Check prompt length — keep under 2000 chars for cron jobs

**LinkedIn not posting:**
- Run: `bash workspace/scripts/postiz-post.sh <draft-file> personal`
- Check PostIz API key in `workspace/config/postiz.json`
- Verify channel IDs at [app.postiz.com](https://app.postiz.com) → Channels

**Google Workspace access failing:**
- Re-run: `npx bb-workspace-setup`
- Check domain-wide delegation in Google Admin Console → Security → API Controls
- Verify scopes include all 7 required scopes (see gworkspace-setup/index.js)

**Claude agent not working:**
- Install: `npm install -g @anthropic-ai/claude-code`
- Set: `ANTHROPIC_API_KEY` in environment or `.env`
- Run: `bash workspace/scripts/doctor.sh` to check status

**Memory growing too large:**
- Run memory compaction: message agent "compact memory now"
- Or manually: `openclaw cron run weekly-memory-compaction`
- MEMORY.md must stay under 200 lines

---

## Support

- OpenClaw docs: [docs.openclaw.ai](https://docs.openclaw.ai)
- OpenClaw skills: [clawhub.ai](https://clawhub.ai)
- Template issues: [github.com/W3JDev/openclaw-biz-template/issues](https://github.com/W3JDev/openclaw-biz-template/issues)
- PostIz docs: [docs.postiz.com](https://docs.postiz.com)
- Google Workspace setup guide: `gworkspace-setup/index.js` (self-documenting)

---

*Built by W3J LLC · OpenClaw Business Team Template v2.0*

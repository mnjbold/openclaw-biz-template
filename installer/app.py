"""
OpenClaw Business Template — Web UI Installer
A simple FastAPI app that guides users through setup and generates their config.

Usage:
  pip install fastapi uvicorn jinja2
  python installer/app.py
  # Open: http://localhost:8181
"""

import json
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse, JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
import uvicorn

app = FastAPI(title="OpenClaw Setup Wizard", version="1.0.0")

TEMPLATE_DIR = Path(__file__).parent.parent
INSTALLER_DIR = Path(__file__).parent

# --- Wizard steps ---
STEPS = [
    "identity",      # Name, company, timezone
    "channel",       # Telegram bot token + chat ID
    "integrations",  # Composio, PostIz, Supabase
    "workspace",     # Employer workspace (optional)
    "persona",       # Autonomous persona agent (optional)
    "models",        # Model selection
    "review",        # Review + generate
    "install",       # Run setup.sh
]

HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>OpenClaw Setup Wizard</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
         background: #0f0f1a; color: #e2e8f0; min-height: 100vh; }
  .wizard { max-width: 760px; margin: 40px auto; padding: 0 20px; }
  h1 { font-size: 28px; font-weight: 700; color: #7c3aed; margin-bottom: 8px; }
  .subtitle { color: #64748b; margin-bottom: 40px; }
  .step-bar { display: flex; gap: 4px; margin-bottom: 40px; }
  .step-dot { flex: 1; height: 4px; border-radius: 2px; background: #1e293b; }
  .step-dot.active { background: #7c3aed; }
  .step-dot.done { background: #22c55e; }
  .card { background: #1e293b; border-radius: 12px; padding: 32px; margin-bottom: 20px;
          border: 1px solid #334155; }
  .card h2 { font-size: 20px; margin-bottom: 6px; color: #f1f5f9; }
  .card p { color: #64748b; margin-bottom: 24px; font-size: 14px; }
  label { display: block; font-size: 13px; color: #94a3b8; margin-bottom: 6px; margin-top: 16px; }
  input, select { width: 100%; padding: 10px 14px; background: #0f172a; border: 1px solid #334155;
                  border-radius: 8px; color: #e2e8f0; font-size: 14px; outline: none; }
  input:focus, select:focus { border-color: #7c3aed; }
  input[type="checkbox"] { width: auto; }
  .hint { font-size: 12px; color: #475569; margin-top: 4px; }
  .btn { display: inline-block; padding: 12px 28px; background: #7c3aed; color: white;
         border: none; border-radius: 8px; font-size: 15px; font-weight: 600; cursor: pointer;
         transition: background 0.2s; text-decoration: none; }
  .btn:hover { background: #6d28d9; }
  .btn-secondary { background: #1e293b; border: 1px solid #334155; color: #94a3b8; }
  .btn-secondary:hover { background: #334155; }
  .btn-row { display: flex; gap: 12px; margin-top: 28px; justify-content: space-between; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px;
           background: #0f172a; color: #7c3aed; border: 1px solid #7c3aed; margin-left: 8px; }
  .section-title { font-size: 13px; text-transform: uppercase; letter-spacing: 0.05em;
                   color: #475569; margin: 24px 0 12px; }
  .optional { color: #475569; font-size: 12px; margin-left: 4px; }
  pre { background: #0f172a; padding: 16px; border-radius: 8px; font-size: 12px;
        overflow-x: auto; color: #94a3b8; white-space: pre-wrap; word-break: break-all; }
  .success { background: #14532d; border: 1px solid #166534; border-radius: 8px; padding: 16px;
             color: #4ade80; margin-bottom: 16px; }
  .error { background: #450a0a; border: 1px solid #7f1d1d; border-radius: 8px; padding: 16px;
           color: #f87171; margin-bottom: 16px; }
  .agent-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }
  .agent-card { background: #0f172a; border: 1px solid #334155; border-radius: 8px; padding: 16px;
                cursor: pointer; transition: border-color 0.2s; }
  .agent-card:hover { border-color: #7c3aed; }
  .agent-card.selected { border-color: #22c55e; background: #052e16; }
  .agent-card h4 { font-size: 14px; margin-bottom: 4px; }
  .agent-card p { font-size: 12px; color: #64748b; margin: 0; }
</style>
</head>
<body>
<div class="wizard">
  <h1>🦞 OpenClaw Setup Wizard</h1>
  <p class="subtitle">Get your AI agent team running in under an hour.</p>

  <div class="step-bar">
    {step_bar}
  </div>

  {content}
</div>
<script>
function nextStep(step) {{
  const form = document.getElementById('wizard-form');
  if (form) {{
    const hidden = document.createElement('input');
    hidden.type = 'hidden';
    hidden.name = 'next_step';
    hidden.value = step;
    form.appendChild(hidden);
    form.submit();
  }}
}}

// Auto-detect Telegram chat ID
async function fetchChatId() {{
  const token = document.getElementById('bot_token')?.value;
  if (!token) return;
  try {{
    const resp = await fetch(`https://api.telegram.org/bot${{token}}/getUpdates`);
    const data = await resp.json();
    if (data.result?.length > 0) {{
      const chatId = data.result[0].message?.chat?.id;
      if (chatId) document.getElementById('telegram_chat_id').value = chatId;
    }}
  }} catch(e) {{ console.error(e); }}
}}
</script>
</body>
</html>"""

def make_step_bar(current_step: str) -> str:
    current_idx = STEPS.index(current_step) if current_step in STEPS else 0
    dots = []
    for i, step in enumerate(STEPS):
        css = "done" if i < current_idx else ("active" if i == current_idx else "")
        dots.append(f'<div class="step-dot {css}" title="{step}"></div>')
    return "".join(dots)

def render(content: str, step: str) -> HTMLResponse:
    page = HTML_PAGE.format(step_bar=make_step_bar(step), content=content)
    return HTMLResponse(page)

@app.get("/", response_class=HTMLResponse)
async def root():
    content = """
    <div class="card">
      <h2>Welcome to OpenClaw Business Setup</h2>
      <p>This wizard will configure your full AI agent team:<br>
      Main agent, CoWork Director (6 desks), Overnight Coder, Bold Ops, Autonomous Persona, and 27 sub-agents.</p>

      <div class="section-title">What you'll set up</div>
      <div class="agent-grid">
        <div class="agent-card selected">
          <h4>🦞 Main Agent</h4>
          <p>Your primary AI partner. Telegram-connected. Decision-maker.</p>
        </div>
        <div class="agent-card selected">
          <h4>🏢 CoWork Director</h4>
          <p>Routes tasks to 6 specialist desks. Your virtual business team.</p>
        </div>
        <div class="agent-card selected">
          <h4>🔒 Bold Ops</h4>
          <p>Isolated employer/client agent. NDA-safe. Google Chat channel.</p>
        </div>
        <div class="agent-card selected">
          <h4>⚡ Autonomous Persona</h4>
          <p>Income-building AI persona. Freelance, hackathons, LinkedIn.</p>
        </div>
        <div class="agent-card selected">
          <h4>🤖 Claude Code Agent</h4>
          <p>Long-running autonomous coding sessions via Claude Code CLI.</p>
        </div>
        <div class="agent-card selected">
          <h4>🎨 27 Sub-Agents</h4>
          <p>10 creative + 17 development. Spawnable on demand.</p>
        </div>
      </div>

      <div class="btn-row">
        <div></div>
        <a href="/step/identity" class="btn">Start Setup →</a>
      </div>
    </div>
    """
    return render(content, "identity")

@app.get("/step/{step}", response_class=HTMLResponse)
async def get_step(step: str, request: Request):
    return render(get_step_content(step, {}), step)

@app.post("/step/{step}", response_class=HTMLResponse)
async def post_step(step: str, request: Request):
    form_data = dict(await request.form())
    # Store in session (simplified — use query params or cookies in production)
    next_step = form_data.get("next_step", get_next_step(step))
    return render(get_step_content(next_step, form_data), next_step)

def get_next_step(current: str) -> str:
    try:
        idx = STEPS.index(current)
        return STEPS[idx + 1] if idx + 1 < len(STEPS) else "install"
    except ValueError:
        return STEPS[0]

def get_step_content(step: str, prev_data: dict) -> str:
    if step == "identity":
        return """
        <div class="card">
          <h2>Step 1 — Your Identity</h2>
          <p>Tell us about yourself. This personalizes all agent SOUL.md files.</p>
          <form id="wizard-form" action="/step/identity" method="post">
            <label>Your Full Name</label>
            <input name="your_name" placeholder="Muhammad Nurunnabi" required>
            <label>Your Company Name</label>
            <input name="your_company" placeholder="Acme Corp" required>
            <label>Your Role / Title</label>
            <input name="your_role" placeholder="Founder & CEO" required>
            <label>Your Handle / Username</label>
            <input name="your_handle" placeholder="yourusername">
            <label>Your Email</label>
            <input name="your_email" type="email" placeholder="you@company.com">
            <label>Your Timezone</label>
            <select name="your_timezone">
              <option value="Asia/Kuala_Lumpur">Asia/Kuala_Lumpur (MYT)</option>
              <option value="America/New_York">America/New_York (ET)</option>
              <option value="America/Los_Angeles">America/Los_Angeles (PT)</option>
              <option value="Europe/London">Europe/London (GMT)</option>
              <option value="Europe/Berlin">Europe/Berlin (CET)</option>
              <option value="Asia/Singapore">Asia/Singapore (SGT)</option>
              <option value="Asia/Tokyo">Asia/Tokyo (JST)</option>
              <option value="Australia/Sydney">Australia/Sydney (AEST)</option>
            </select>
            <label>Active Hours Start (your local time)</label>
            <input name="active_start" type="time" value="20:00">
            <label>Active Hours End (your local time)</label>
            <input name="active_end" type="time" value="05:00">
            <label>Primary Goal</label>
            <input name="primary_goal" placeholder="Build passive income to $10K/month MRR">
            <div class="btn-row">
              <a href="/" class="btn btn-secondary">← Back</a>
              <button type="submit" class="btn">Next →</button>
            </div>
          </form>
        </div>
        """
    elif step == "channel":
        return """
        <div class="card">
          <h2>Step 2 — Telegram Channel</h2>
          <p>Your main agent receives messages via Telegram. Create a bot at @BotFather first.</p>
          <form id="wizard-form" action="/step/channel" method="post">
            <label>Telegram Bot Token</label>
            <input id="bot_token" name="telegram_bot_token" placeholder="1234567890:AABBCC..." required>
            <p class="hint">Get from @BotFather on Telegram → /newbot</p>
            <label>Your Telegram Chat ID</label>
            <input id="telegram_chat_id" name="telegram_chat_id" placeholder="1234567890" required>
            <p class="hint">Send /start to your bot, then <button type="button" onclick="fetchChatId()" style="background:none;border:none;color:#7c3aed;cursor:pointer;font-size:12px;">auto-detect →</button> or message @userinfobot to get your ID</p>
            <label>Agent Name (what your main agent is called)</label>
            <input name="agent_name" placeholder="Luffy" value="Luffy">
            <label>Persona Agent Name (your autonomous income persona)</label>
            <input name="persona_name" placeholder="MR BIJOU">
            <p class="hint">Optional — the name of your autonomous income-building agent persona</p>
            <div class="btn-row">
              <a href="/step/identity" class="btn btn-secondary">← Back</a>
              <button type="submit" class="btn">Next →</button>
            </div>
          </form>
        </div>
        """
    elif step == "integrations":
        return """
        <div class="card">
          <h2>Step 3 — Integrations</h2>
          <p>Connect the external services your agents will use.</p>
          <form id="wizard-form" action="/step/integrations" method="post">
            <div class="section-title">Required</div>
            <label>OpenCode Go API Key <span class="badge">Free</span></label>
            <input name="opencode_api_key" placeholder="your-opencode-api-key" required>
            <p class="hint">Get from opencode.ai — powers kimi-k2.5, glm-5, minimax-m2.5 (all free)</p>

            <label>Composio API Key <span class="badge">Free tier</span></label>
            <input name="composio_api_key" placeholder="ck_xxxxxxxxxxxxxxxxxxxx" required>
            <p class="hint">Get from app.composio.dev — enables Gmail, Drive, Calendar, LinkedIn</p>

            <div class="section-title">Optional but Recommended</div>
            <label>PostIz API Key <span class="badge">LinkedIn automation</span></label>
            <input name="postiz_api_key" placeholder="pz_xxxxxxxxxxxxxxxxxxxx">
            <p class="hint">Get from app.postiz.com → Settings → API Key</p>

            <label>LinkedIn Personal Channel ID</label>
            <input name="linkedin_personal_channel" placeholder="from PostIz /integrations">

            <label>LinkedIn Company Page Channel ID <span class="optional">(optional)</span></label>
            <input name="linkedin_company_channel" placeholder="from PostIz /integrations">

            <label>Supabase Project Ref <span class="optional">(optional)</span></label>
            <input name="supabase_project_ref" placeholder="your-project-ref">

            <label>Anthropic API Key <span class="badge">For Claude agents</span></label>
            <input name="anthropic_api_key" placeholder="sk-ant-...">
            <p class="hint">Required for claude-automation and claude-code-agent. Get from console.anthropic.com</p>

            <div class="btn-row">
              <a href="/step/channel" class="btn btn-secondary">← Back</a>
              <button type="submit" class="btn">Next →</button>
            </div>
          </form>
        </div>
        """
    elif step == "workspace":
        return """
        <div class="card">
          <h2>Step 4 — Employer / Client Workspace</h2>
          <p>If you work for an employer or have NDA-sensitive clients, set up the isolated bold-ops agent.
          This agent works in a completely separate workspace — data never crosses over.</p>
          <form id="wizard-form" action="/step/workspace" method="post">
            <label>
              <input type="checkbox" name="enable_bold_ops" value="yes" checked>
              Enable isolated employer/client agent (bold-ops)
            </label>
            <label>Employer / Client Name</label>
            <input name="employer_name" placeholder="Acme Corp Client">
            <label>Employer Workspace Path</label>
            <input name="employer_workspace" placeholder="/root/.openclaw/workspace/employer" value="/root/.openclaw/workspace/employer">
            <label>Google Chat Account ID (for routing)</label>
            <input name="google_chat_account" placeholder="default" value="default">
            <p class="hint">Employer messages via Google Chat → routed to bold-ops agent</p>

            <div class="section-title">Team Members (for meeting notes access)</div>
            <label>Team member emails (comma-separated)</label>
            <input name="team_emails" placeholder="alice@company.com, bob@company.com">
            <p class="hint">Run npx bb-workspace-setup to configure Google Workspace auth</p>

            <div class="btn-row">
              <a href="/step/integrations" class="btn btn-secondary">← Back</a>
              <button type="submit" class="btn">Next →</button>
            </div>
          </form>
        </div>
        """
    elif step == "models":
        return """
        <div class="card">
          <h2>Step 5 — Model Configuration</h2>
          <p>Configure which AI models power each agent. Free models recommended.</p>
          <form id="wizard-form" action="/step/models" method="post">
            <label>Main Agent Model</label>
            <select name="main_model">
              <option value="opencode-go/kimi-k2.5" selected>kimi-k2.5 (Free — Best quality)</option>
              <option value="opencode-go/glm-5">glm-5 (Free — Good creative)</option>
              <option value="claude-sonnet-4-6">Claude Sonnet 4.6 (Paid — Best overall)</option>
            </select>
            <label>Content / Creative Model</label>
            <select name="content_model">
              <option value="opencode-go/glm-5" selected>glm-5 (Free — Best for creative)</option>
              <option value="opencode-go/kimi-k2.5">kimi-k2.5 (Free — Best quality)</option>
            </select>
            <label>Background / Cron Model</label>
            <select name="cron_model">
              <option value="opencode-go/minimax-m2.5" selected>minimax-m2.5 (Free — Cheapest)</option>
              <option value="opencode-go/glm-5">glm-5 (Free — Better quality)</option>
            </select>
            <label>Daily Briefing Time (your local time)</label>
            <input name="briefing_time" type="time" value="22:00">
            <label>LinkedIn Content Time (your local time)</label>
            <input name="linkedin_time" type="time" value="09:00">
            <label>Opportunity Scan Time (your local time)</label>
            <input name="scan_time" type="time" value="22:00">
            <div class="btn-row">
              <a href="/step/workspace" class="btn btn-secondary">← Back</a>
              <button type="submit" class="btn">Review →</button>
            </div>
          </form>
        </div>
        """
    elif step == "review":
        return """
        <div class="card">
          <h2>Step 6 — Review Configuration</h2>
          <p>Review what will be installed. Click Generate Config to create all files.</p>
          <div class="section-title">Files to Create</div>
          <pre>~/.openclaw/
├── openclaw.json            (main config)
├── AGENTS.md                (agent instructions)
├── agents/
│   ├── main/                (SOUL, HEARTBEAT, TOOLS, BOOTSTRAP, AGENTS, IDENTITY, USER)
│   ├── cowork/              (SOUL, ROUTING, 6 desks)
│   ├── bold-ops/            (SOUL, HEARTBEAT)
│   ├── persona/             (SOUL, HEARTBEAT)
│   ├── claude-automation/   (SOUL)
│   ├── claude-code-agent/   (SOUL, TOOLS)
│   ├── creative/            (10 sub-agents)
│   └── development/         (17 sub-agents)
├── workspace/
│   ├── HEARTBEAT.md
│   ├── OPERATIONS.md
│   ├── MEMORY.md
│   ├── scripts/postiz-post.sh
│   ├── scripts/doctor.sh
│   └── scripts/cost-tracker.sh
└── cron/jobs.json           (6 pre-built cron jobs)</pre>

          <div class="btn-row">
            <a href="/step/models" class="btn btn-secondary">← Back</a>
            <a href="/generate" class="btn">Generate Config →</a>
          </div>
        </div>
        """
    elif step == "install":
        return """
        <div class="card">
          <h2>Step 7 — Install</h2>
          <p>Run the setup script to install everything.</p>
          <div class="section-title">Quick Install</div>
          <pre>cd /path/to/openclaw-biz-template
bash setup.sh</pre>
          <div class="section-title">Or with npx (from anywhere)</div>
          <pre>npx openclaw-setup</pre>
          <div class="section-title">After Install</div>
          <pre>openclaw restart           # Apply new config
openclaw cron list         # Verify cron jobs
openclaw agents list       # Verify agents
bash workspace/scripts/doctor.sh   # Health check</pre>
          <div class="btn-row">
            <a href="/step/review" class="btn btn-secondary">← Back</a>
            <a href="/generate" class="btn">Download Config</a>
          </div>
        </div>
        """
    else:
        return f'<div class="card"><h2>Unknown step: {step}</h2></div>'

@app.get("/generate")
async def generate_config():
    """Generate and return the .env file based on wizard inputs."""
    # In production, this would use session data from the wizard steps
    # For now, return a template .env file
    return HTMLResponse("""
    <div style="font-family: system-ui; max-width: 600px; margin: 40px auto; padding: 20px; background: #1e293b; border-radius: 12px; color: #e2e8f0;">
      <h2 style="color: #7c3aed; margin-bottom: 16px;">Config Generated!</h2>
      <p style="color: #94a3b8; margin-bottom: 20px;">
        In the full version, your configuration would be downloaded here.
        For now, copy .env.example to .env, fill in your values, and run setup.sh.
      </p>
      <pre style="background: #0f172a; padding: 16px; border-radius: 8px; font-size: 12px; color: #94a3b8;">
cp .env.example .env
nano .env           # Fill in your values
bash setup.sh       # Install everything
openclaw restart    # Apply config
</pre>
      <div style="margin-top: 20px;">
        <a href="/" style="color: #7c3aed;">← Start over</a>
      </div>
    </div>
    """)

@app.get("/health")
async def health():
    return {"status": "ok", "version": "1.0.0"}

if __name__ == "__main__":
    PORT = int(os.environ.get("PORT", 8181))
    print(f"\n🦞 OpenClaw Setup Wizard")
    print(f"   Open: http://localhost:{PORT}")
    print(f"   Press Ctrl+C to stop\n")
    uvicorn.run("app:app", host="0.0.0.0", port=PORT, reload=False)

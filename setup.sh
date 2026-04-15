#!/bin/bash
# setup.sh — OpenClaw Business Template Installer
# Interactive CLI wizard for 1-hour team setup
# Supports: Linux, macOS, WSL2
#
# Usage: bash setup.sh [--yes] [--dir PATH]
#   --yes       Non-interactive: skip confirmations (use defaults)
#   --dir PATH  Install to custom directory (default: ~/.openclaw)

set -euo pipefail

# ── Colors ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Platform detection ────────────────────────────────────
IS_WSL=false
IS_MAC=false
IS_LINUX=false

if [ -f /proc/version ] && grep -qi microsoft /proc/version; then
  IS_WSL=true
elif [ "$(uname)" = "Darwin" ]; then
  IS_MAC=true
else
  IS_LINUX=true
fi

# ── Args ──────────────────────────────────────────────────
NONINTERACTIVE=false
OPENCLAW_DIR="${HOME}/.openclaw"

while [[ $# -gt 0 ]]; do
  case $1 in
    --yes) NONINTERACTIVE=true; shift ;;
    --dir) OPENCLAW_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Helpers ───────────────────────────────────────────────
info()    { echo -e "${BLUE}ℹ${NC} $*"; }
ok()      { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}!${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*"; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }
ask()     { echo -en "${YELLOW}?${NC} $1: "; }

prompt() {
  local VAR="$1"
  local PROMPT="$2"
  local DEFAULT="${3:-}"
  local VALUE=""

  if $NONINTERACTIVE && [ -n "$DEFAULT" ]; then
    eval "$VAR='$DEFAULT'"
    return
  fi

  ask "$PROMPT"
  if [ -n "$DEFAULT" ]; then
    echo -n "[$DEFAULT] "
  fi
  read -r VALUE
  VALUE="${VALUE:-$DEFAULT}"
  eval "$VAR='$VALUE'"
}

confirm() {
  local PROMPT="$1"
  local DEFAULT="${2:-y}"
  local ANSWER

  if $NONINTERACTIVE; then
    [[ "$DEFAULT" == "y" ]] && return 0 || return 1
  fi

  ask "$PROMPT [y/n, default: $DEFAULT]"
  read -r ANSWER
  ANSWER="${ANSWER:-$DEFAULT}"
  [[ "$ANSWER" =~ ^[Yy] ]]
}

# ── Banner ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║   OpenClaw Business Team Setup — v2.0.0      ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Platform: $([ $IS_WSL = true ] && echo WSL2 || ([ $IS_MAC = true ] && echo macOS || echo Linux))"
echo -e "Template: ${TEMPLATE_DIR}"
echo -e "Install:  ${OPENCLAW_DIR}"
echo ""
echo -e "This wizard takes about ${BOLD}30–60 minutes${NC}."
echo -e "You'll need: Telegram bot token, OpenCode Go API key, and optionally Composio, PostIz, Supabase."
echo ""

if ! confirm "Ready to begin?"; then
  echo "Setup cancelled."
  exit 0
fi

# ── Step 1: Check prerequisites ───────────────────────────
section "STEP 1 — Prerequisites"

MISSING=()

check_tool() {
  local TOOL="$1"
  local INSTALL_MSG="${2:-Install $1 from its official site}"
  if command -v "$TOOL" &>/dev/null; then
    VER=$("$TOOL" --version 2>/dev/null | head -1 || echo "installed")
    ok "$TOOL: $VER"
  else
    error "$TOOL: NOT FOUND — $INSTALL_MSG"
    MISSING+=("$TOOL")
  fi
}

check_tool "openclaw" "npm install -g openclaw"
check_tool "node" "https://nodejs.org (v18+)"
check_tool "python3" "https://python.org"
check_tool "git" "https://git-scm.com"

NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1 || echo 0)
if [ "$NODE_VERSION" -lt 18 ] 2>/dev/null; then
  error "Node.js v18+ required (found v${NODE_VERSION})"
  MISSING+=("node>=18")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  error "Missing required tools: ${MISSING[*]}"
  error "Please install them and re-run setup.sh"
  exit 1
fi

ok "All prerequisites met"

# ── Step 2: Identity ──────────────────────────────────────
section "STEP 2 — Your Identity"

prompt YOUR_NAME        "Your full name" "Alex"
prompt YOUR_HANDLE      "Your handle/username (no @)" "alex"
prompt YOUR_COMPANY     "Company or project name" "MyCompany"
prompt YOUR_EMAIL       "Your email address"
prompt YOUR_TIMEZONE    "Timezone (e.g., Asia/Kuala_Lumpur, America/New_York)" "UTC"
prompt AGENT_NAME       "Name for your main agent (e.g., Atlas, Sage, Vance, Nova)" "Atlas"
prompt PERSONA_NAME     "Name for your autonomous persona agent (e.g., MR NOVA, MAX, ACE)" "NOVA"

echo ""
info "Identity configured:"
echo "  Name: $YOUR_NAME (@$YOUR_HANDLE)"
echo "  Company: $YOUR_COMPANY"
echo "  Agent: $AGENT_NAME | Persona: $PERSONA_NAME"
echo "  Timezone: $YOUR_TIMEZONE"

# ── Step 3: Telegram ──────────────────────────────────────
section "STEP 3 — Telegram Bot"

echo ""
echo -e "Create a Telegram bot via ${CYAN}@BotFather${NC}:"
echo "  1. Message @BotFather on Telegram"
echo "  2. Send: /newbot"
echo "  3. Choose a name and username"
echo "  4. Copy the bot token"
echo ""

prompt TELEGRAM_BOT_TOKEN "Telegram bot token" ""
prompt TELEGRAM_CHAT_ID   "Your Telegram chat ID (numeric)" ""

if [ -z "$TELEGRAM_CHAT_ID" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  echo ""
  info "Auto-detecting your chat ID..."
  RESPONSE=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates" 2>/dev/null || echo "{}")
  DETECTED_ID=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); msgs=d.get('result',[]); print(msgs[-1]['message']['chat']['id'] if msgs else '')" "$RESPONSE" 2>/dev/null || echo "")
  if [ -n "$DETECTED_ID" ]; then
    ok "Detected chat ID: $DETECTED_ID"
    TELEGRAM_CHAT_ID="$DETECTED_ID"
  else
    warn "Could not auto-detect. Send any message to your bot first, then re-run."
    warn "Or visit: https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates"
  fi
fi

# ── Step 4: API Keys ──────────────────────────────────────
section "STEP 4 — API Keys"

echo ""
echo -e "${YELLOW}Required:${NC}"
prompt OPENCODE_GO_API_KEY "OpenCode Go API key (sign up: opencode.go — free models)" ""

echo ""
echo -e "${YELLOW}Optional — more features unlock as you add these:${NC}"
prompt COMPOSIO_API_KEY    "Composio API key (Gmail, Drive, LinkedIn, GitHub — skip: press Enter)" ""
prompt POSTIZ_API_KEY      "PostIz API key (LinkedIn auto-posting — skip: press Enter)" ""
prompt SUPABASE_PROJECT_REF "Supabase project ref (database — skip: press Enter)" ""
prompt ANTHROPIC_API_KEY   "Anthropic API key (paid Claude models — skip: press Enter)" ""

if [ -n "$POSTIZ_API_KEY" ]; then
  echo ""
  info "PostIz LinkedIn channels (get from app.postiz.com → Channels):"
  prompt POSTIZ_PERSONAL_CHANNEL "PostIz personal LinkedIn channel ID" ""
  prompt POSTIZ_BRAND_CHANNEL    "PostIz brand LinkedIn channel ID (skip if one account)" ""
fi

# ── Step 5: Employer workspace ────────────────────────────
section "STEP 5 — Employer Workspace (Optional)"

echo ""
echo -e "If you work for an employer and want an ${BOLD}isolated${NC} agent (bold-ops pattern):"
echo "  - Separate workspace, strict NDA wall"
echo "  - Can connect to Google Chat for team communication"
echo ""

USE_EMPLOYER=false
if confirm "Set up employer workspace?"; then
  USE_EMPLOYER=true
  prompt EMPLOYER_NAME      "Employer name" "Company"
  prompt EMPLOYER_WORKSPACE "Employer workspace path" "${OPENCLAW_DIR}/workspace/employer"
fi

# ── Step 6: Create directory structure ────────────────────
section "STEP 6 — Creating Directory Structure"

mkdir -p "${OPENCLAW_DIR}"/{agents,config,cron,skills,workspace/memory,workspace/drafts,workspace/logs,workspace/ops,workspace/outputs,workspace/config,workspace/.learnings,workspace/ops/briefings}

# Agent directories
for AGENT in main cowork bold-ops persona claude-automation claude-code-agent; do
  mkdir -p "${OPENCLAW_DIR}/agents/${AGENT}/agent"
done

# Cowork desks
for DESK in ops-desk content-desk data-desk code-desk research-desk memory-desk; do
  mkdir -p "${OPENCLAW_DIR}/agents/cowork/desks/${DESK}/agent"
done

# Sub-agents
for AGENT in ad-copywriter brand-designer copywriter proofreader ux-researcher storyboard-writer video-scripter podcast-producer audio-producer thumbnail-designer; do
  mkdir -p "${OPENCLAW_DIR}/agents/creative/${AGENT}/agent"
done
for AGENT in bug-hunter code-reviewer test-writer qa-tester github-pr-reviewer github-issue-triager pr-merger api-documentation api-tester schema-designer script-builder migration-helper dependency-scanner changelog blockchain-analyst ecommerce-dev game-designer; do
  mkdir -p "${OPENCLAW_DIR}/agents/development/${AGENT}/agent"
done

if $USE_EMPLOYER; then
  mkdir -p "${EMPLOYER_WORKSPACE:-${OPENCLAW_DIR}/workspace/employer}"
fi
mkdir -p "${OPENCLAW_DIR}/workspace/persona"

ok "Directory structure created"

# ── Step 7: Copy agent files ──────────────────────────────
section "STEP 7 — Installing Agent Files"

# Function to copy and substitute placeholders
install_agent_file() {
  local SRC="$1"
  local DEST="$2"

  if [ ! -f "$SRC" ]; then
    return
  fi

  mkdir -p "$(dirname "$DEST")"

  sed \
    -e "s/{{YOUR_NAME}}/${YOUR_NAME}/g" \
    -e "s/{{YOUR_HANDLE}}/${YOUR_HANDLE}/g" \
    -e "s/{{YOUR_COMPANY}}/${YOUR_COMPANY}/g" \
    -e "s/{{YOUR_EMAIL}}/${YOUR_EMAIL}/g" \
    -e "s/{{AGENT_NAME}}/${AGENT_NAME}/g" \
    -e "s/{{PERSONA_NAME}}/${PERSONA_NAME}/g" \
    -e "s/{{TIMEZONE}}/${YOUR_TIMEZONE}/g" \
    -e "s/{{OPENCLAW_DIR}}/${OPENCLAW_DIR//\//\\/}/g" \
    -e "s/{{EMPLOYER_NAME}}/${EMPLOYER_NAME:-YourEmployer}/g" \
    -e "s/{{EMPLOYER_WORKSPACE_PATH}}/${EMPLOYER_WORKSPACE:-${OPENCLAW_DIR}\/workspace\/employer}/g" \
    -e "s/{{INSTALL_DATE}}/$(date -u +%Y-%m-%dT%H:%M:%SZ)/g" \
    "$SRC" > "$DEST"
}

# Copy all agent files
for AGENT_DIR in "${TEMPLATE_DIR}"/agents/*/; do
  AGENT=$(basename "$AGENT_DIR")
  for FILE in "$AGENT_DIR"*.md; do
    [ -f "$FILE" ] || continue
    FILENAME=$(basename "$FILE")
    install_agent_file "$FILE" "${OPENCLAW_DIR}/agents/${AGENT}/${FILENAME}"
  done
done

# Copy cowork desks
for DESK_DIR in "${TEMPLATE_DIR}"/agents/cowork/desks/*/; do
  DESK=$(basename "$DESK_DIR")
  for FILE in "$DESK_DIR"*.md; do
    [ -f "$FILE" ] || continue
    FILENAME=$(basename "$FILE")
    install_agent_file "$FILE" "${OPENCLAW_DIR}/agents/cowork/desks/${DESK}/${FILENAME}"
  done
done

# Copy sub-agents
for TYPE in creative development; do
  for AGENT_DIR in "${TEMPLATE_DIR}"/agents/${TYPE}/*/; do
    AGENT=$(basename "$AGENT_DIR")
    for FILE in "$AGENT_DIR"*.md; do
      [ -f "$FILE" ] || continue
      FILENAME=$(basename "$FILE")
      install_agent_file "$FILE" "${OPENCLAW_DIR}/agents/${TYPE}/${AGENT}/${FILENAME}"
    done
  done
done

# Copy workspace files
for FILE in "${TEMPLATE_DIR}"/workspace/*.md; do
  [ -f "$FILE" ] || continue
  FILENAME=$(basename "$FILE")
  install_agent_file "$FILE" "${OPENCLAW_DIR}/workspace/${FILENAME}"
done

# Copy root files
for FILE in AGENTS.md; do
  [ -f "${TEMPLATE_DIR}/${FILE}" ] && install_agent_file "${TEMPLATE_DIR}/${FILE}" "${OPENCLAW_DIR}/${FILE}"
done

ok "Agent files installed"

# ── Step 8: Generate openclaw.json ────────────────────────
section "STEP 8 — Generating openclaw.json"

OPENCLAW_JSON="${OPENCLAW_DIR}/openclaw.json"

if [ -f "$OPENCLAW_JSON" ]; then
  warn "openclaw.json already exists — backing up to openclaw.json.bak"
  cp "$OPENCLAW_JSON" "${OPENCLAW_JSON}.bak"
fi

sed \
  -e "s/{{OPENCLAW_DIR}}/${OPENCLAW_DIR//\//\\/}/g" \
  -e "s/{{TELEGRAM_BOT_TOKEN}}/${TELEGRAM_BOT_TOKEN}/g" \
  -e "s/{{TELEGRAM_CHAT_ID}}/${TELEGRAM_CHAT_ID}/g" \
  -e "s/{{COMPOSIO_API_KEY}}/${COMPOSIO_API_KEY}/g" \
  -e "s/{{SUPABASE_PROJECT_REF}}/${SUPABASE_PROJECT_REF}/g" \
  -e "s/{{OPENCODE_GO_API_KEY}}/${OPENCODE_GO_API_KEY}/g" \
  -e "s/{{ANTHROPIC_API_KEY}}/${ANTHROPIC_API_KEY}/g" \
  -e "s/{{GOOGLE_AI_API_KEY}}//g" \
  -e "s/{{OPENAI_API_KEY}}//g" \
  -e "s/{{GOOGLECHAT_AUDIENCE_URL}}//g" \
  -e "s/{{TIMEZONE}}/${YOUR_TIMEZONE}/g" \
  -e "s/{{INSTALL_DATE}}/$(date -u +%Y-%m-%dT%H:%M:%SZ)/g" \
  -e "s/{{PERSONA_NAME}}/${PERSONA_NAME}/g" \
  "${TEMPLATE_DIR}/openclaw.json.template" > "$OPENCLAW_JSON"

ok "openclaw.json generated"

# ── Step 9: Generate cron jobs ────────────────────────────
section "STEP 9 — Configuring Cron Jobs"

CRON_DIR="${OPENCLAW_DIR}/cron"
mkdir -p "$CRON_DIR"

sed \
  -e "s/{{TELEGRAM_CHAT_ID}}/${TELEGRAM_CHAT_ID}/g" \
  "${TEMPLATE_DIR}/cron/jobs.template.json" > "${CRON_DIR}/jobs.json"

ok "Cron jobs configured"

# ── Step 10: Configure MCP servers ────────────────────────
section "STEP 10 — MCP Server Configuration"

CONFIG_DIR="${OPENCLAW_DIR}/config"
mkdir -p "$CONFIG_DIR"

sed \
  -e "s/{{COMPOSIO_API_KEY}}/${COMPOSIO_API_KEY}/g" \
  -e "s/{{SUPABASE_PROJECT_REF}}/${SUPABASE_PROJECT_REF}/g" \
  "${TEMPLATE_DIR}/config/mcporter.json.template" > "${CONFIG_DIR}/mcporter.json"

ok "MCP servers configured"

# ── Step 11: PostIz config ────────────────────────────────
section "STEP 11 — PostIz LinkedIn Config"

POSTIZ_CONFIG="${OPENCLAW_DIR}/workspace/config/postiz.json"
cat > "$POSTIZ_CONFIG" << POSTIZ_EOF
{
  "apiKey": "${POSTIZ_API_KEY:-POSTIZ_API_KEY_HERE}",
  "baseUrl": "https://api.postiz.com/public/v1",
  "channels": {
    "personal": "${POSTIZ_PERSONAL_CHANNEL:-LINKEDIN_PERSONAL_CHANNEL_ID}",
    "brand": "${POSTIZ_BRAND_CHANNEL:-LINKEDIN_BRAND_CHANNEL_ID}"
  },
  "_setup": {
    "step1": "Get API key: app.postiz.com → Settings → API",
    "step2": "Connect LinkedIn in PostIz",
    "step3": "Get channel IDs: app.postiz.com → Channels",
    "step4": "Replace values in this file"
  }
}
POSTIZ_EOF

# Copy posting script
if [ -f "${TEMPLATE_DIR}/workspace/scripts/postiz-post.sh" ]; then
  cp "${TEMPLATE_DIR}/workspace/scripts/postiz-post.sh" "${OPENCLAW_DIR}/workspace/scripts/postiz-post.sh"
  chmod +x "${OPENCLAW_DIR}/workspace/scripts/postiz-post.sh"
  ok "PostIz posting script installed"
fi

if [ -n "$POSTIZ_API_KEY" ]; then
  ok "PostIz configured (API key set)"
else
  warn "PostIz API key not set — edit workspace/config/postiz.json later"
fi

# ── Step 12: Install workspace scripts ────────────────────
section "STEP 12 — Workspace Scripts"

SCRIPTS_DIR="${OPENCLAW_DIR}/workspace/scripts"
mkdir -p "$SCRIPTS_DIR"

for SCRIPT in doctor.sh cost-tracker.sh; do
  if [ -f "${TEMPLATE_DIR}/workspace/scripts/${SCRIPT}" ]; then
    cp "${TEMPLATE_DIR}/workspace/scripts/${SCRIPT}" "${SCRIPTS_DIR}/${SCRIPT}"
    chmod +x "${SCRIPTS_DIR}/${SCRIPT}"
    ok "$SCRIPT installed"
  fi
done

# Initialize cost tracker
bash "${SCRIPTS_DIR}/cost-tracker.sh" init 2>/dev/null || true
ok "Cost tracker initialized"

# Initialize learning files
touch "${OPENCLAW_DIR}/workspace/.learnings/LEARNINGS.md"
touch "${OPENCLAW_DIR}/workspace/.learnings/ERRORS.md"

# Create today's memory file
TODAY=$(date +%Y-%m-%d)
cat > "${OPENCLAW_DIR}/workspace/memory/${TODAY}.md" << MEMORY_EOF
# ${TODAY} — First Day

## Setup
- OpenClaw Business Template installed
- Owner: ${YOUR_NAME} (${YOUR_COMPANY})
- Agent: ${AGENT_NAME}
- Install path: ${OPENCLAW_DIR}
MEMORY_EOF

ok "Workspace initialized"

# ── Step 13: Install skills ────────────────────────────────
section "STEP 13 — Skills"

if [ -d "${TEMPLATE_DIR}/skills" ]; then
  cp -r "${TEMPLATE_DIR}/skills" "${OPENCLAW_DIR}/skills"
  ok "Skill templates copied"
fi

# Attempt to install skills via openclaw if available
if command -v openclaw &>/dev/null; then
  info "Installing skills via clawhub..."
  for SKILL in word-docx excel-xlsx powerpoint-pptx nano-pdf data-analysis github marketing-skills memory-setup agent-autonomy-kit; do
    openclaw skill install "$SKILL" 2>/dev/null && ok "Installed: $SKILL" || warn "Could not install $SKILL — install manually: openclaw skill install $SKILL"
  done
fi

# ── Step 14: Start OpenClaw ────────────────────────────────
section "STEP 14 — Starting OpenClaw"

if command -v openclaw &>/dev/null; then
  info "Starting OpenClaw daemon..."
  openclaw start 2>/dev/null || warn "openclaw start failed — try: openclaw restart"
  sleep 2

  info "Checking status..."
  openclaw status 2>/dev/null || true

  info "Registered agents:"
  openclaw agents list 2>/dev/null || true

  info "Cron jobs:"
  openclaw cron list 2>/dev/null || true
else
  warn "openclaw CLI not found — install it: npm install -g openclaw"
fi

# ── Step 15: Save .env ────────────────────────────────────
section "STEP 15 — Saving Environment"

ENV_FILE="${OPENCLAW_DIR}/.env"
cat > "$ENV_FILE" << ENV_EOF
# OpenClaw .env — DO NOT COMMIT
OPENCLAW_DIR=${OPENCLAW_DIR}
OPENCODE_GO_API_KEY=${OPENCODE_GO_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
COMPOSIO_API_KEY=${COMPOSIO_API_KEY}
SUPABASE_PROJECT_REF=${SUPABASE_PROJECT_REF}
POSTIZ_API_KEY=${POSTIZ_API_KEY}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
ENV_EOF

chmod 600 "$ENV_FILE"
ok ".env saved (chmod 600)"

# ── Step 16: Run doctor ────────────────────────────────────
section "STEP 16 — Health Check"

if [ -f "${SCRIPTS_DIR}/doctor.sh" ]; then
  info "Running initial health check..."
  bash "${SCRIPTS_DIR}/doctor.sh" 2>/dev/null | tail -20 || true
fi

# ── Done ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║         Setup Complete!                      ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Your OpenClaw instance: ${BOLD}${OPENCLAW_DIR}${NC}"
echo ""
echo -e "${BOLD}What was installed:${NC}"
echo "  ✓ 6 core agents (main, cowork, bold-ops, persona, claude-automation, claude-code-agent)"
echo "  ✓ 6 CoWork desks (ops, content, data, code, research, memory)"
echo "  ✓ 27 specialist sub-agents (10 creative + 17 development)"
echo "  ✓ 9 scheduled cron jobs"
echo "  ✓ Cost tracker + health monitor"
echo "  ✓ LinkedIn PostIz pipeline"
echo ""
echo -e "${BOLD}Immediate next steps:${NC}"
echo "  1. Edit agents/main/SOUL.md — customize your agent's identity and missions"
echo "  2. Edit agents/main/USER.md — fill in your profile"
echo "  3. Set PostIz channel IDs: workspace/config/postiz.json"
echo ""

if [ -n "$POSTIZ_API_KEY" ] && [ -z "$POSTIZ_PERSONAL_CHANNEL" ]; then
  echo -e "  ${YELLOW}!${NC} PostIz channel IDs still needed — get from app.postiz.com → Channels"
fi

if [ -z "$COMPOSIO_API_KEY" ]; then
  echo -e "  ${YELLOW}!${NC} Composio not configured — needed for Gmail, Drive, Calendar, LinkedIn tools"
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo -e "  ${YELLOW}!${NC} Anthropic key not set — claude-automation and claude-code-agent will not work"
fi

echo ""
echo -e "${BOLD}Google Workspace (team email/calendar):${NC}"
echo "  npx bb-workspace-setup"
echo ""
echo -e "${BOLD}Test your setup:${NC}"
echo "  1. Send any message to your Telegram bot @${YOUR_HANDLE}_bot"
echo "  2. Run: bash workspace/scripts/doctor.sh"
echo ""
echo -e "${BOLD}Full guide:${NC} ${OPENCLAW_DIR}/README.md"
echo ""

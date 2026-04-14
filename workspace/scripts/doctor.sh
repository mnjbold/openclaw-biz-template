#!/bin/bash
# doctor.sh — OpenClaw Agent Health Check
# Checks all agents, cron jobs, tools, memory, and configs
# Run: bash workspace/scripts/doctor.sh
# Schedule: Sunday 06:00 via cron (learnings-capture job)

set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENCLAW_DIR="$(dirname "$WORKSPACE_DIR")"
LOG_FILE="$WORKSPACE_DIR/ops/doctor-$(date +%Y-%m-%d).log"
REPORT_FILE="$WORKSPACE_DIR/ops/briefings/doctor-$(date +%Y-%m-%d).md"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

mkdir -p "$WORKSPACE_DIR/ops/briefings"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0
ISSUES=()

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
ok() { log "✓ $*"; ((PASS++)); }
warn() { log "! $*"; ((WARN++)); ISSUES+=("WARN: $*"); }
fail() { log "✗ $*"; ((FAIL++)); ISSUES+=("FAIL: $*"); }
section() { log ""; log "=== $* ==="; }

# --- Tool Checks ---
section "TOOLS"

for tool in openclaw mcporter brv node python3 git gh; do
  if command -v "$tool" &>/dev/null; then
    VER=$("$tool" --version 2>/dev/null | head -1 || echo "installed")
    ok "$tool: $VER"
  else
    fail "$tool: NOT FOUND"
  fi
done

# --- OpenClaw Daemon ---
section "OPENCLAW DAEMON"
if openclaw status 2>/dev/null | grep -q "running"; then
  ok "OpenClaw daemon: running"
else
  fail "OpenClaw daemon: not running — run: openclaw start"
fi

# --- Agent Checks ---
section "AGENTS"
if command -v openclaw &>/dev/null; then
  AGENT_LIST=$(openclaw agents list 2>/dev/null || echo "")
  for agent_id in main cowork bold-ops; do
    if echo "$AGENT_LIST" | grep -q "$agent_id"; then
      ok "Agent: $agent_id registered"
    else
      fail "Agent: $agent_id NOT registered — check openclaw.json"
    fi
  done
fi

# --- Agent File Checks ---
section "AGENT FILES"
for agent_dir in "$OPENCLAW_DIR/agents"/{main,cowork,bold-ops}/; do
  agent_name=$(basename "$agent_dir")
  if [ -d "$agent_dir" ]; then
    for required_file in SOUL.md; do
      if [ -f "$agent_dir/$required_file" ]; then
        ok "$agent_name/$required_file: exists"
      elif [ -f "$agent_dir/agent/$required_file" ]; then
        ok "$agent_name/agent/$required_file: exists"
      else
        fail "$agent_name/$required_file: MISSING"
      fi
    done
  else
    fail "Agent directory missing: $agent_dir"
  fi
done

# --- Cron Jobs ---
section "CRON JOBS"
if command -v openclaw &>/dev/null; then
  CRON_OUTPUT=$(openclaw cron list 2>/dev/null || echo "unavailable")
  if echo "$CRON_OUTPUT" | grep -q "consecutiveErrors: [1-9]"; then
    FAILING=$(echo "$CRON_OUTPUT" | grep -B5 "consecutiveErrors: [1-9]" | grep "name:" | head -5)
    warn "Cron jobs with errors: $FAILING"
  else
    ok "Cron jobs: no consecutive errors"
  fi

  # Check if critical jobs exist
  for job_name in "Nightly" "LinkedIn"; do
    if echo "$CRON_OUTPUT" | grep -qi "$job_name"; then
      ok "Cron job '$job_name': present"
    else
      warn "Cron job '$job_name': not found — check cron/jobs.json"
    fi
  done
fi

# --- Memory Files ---
section "MEMORY"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v -1d +%Y-%m-%d 2>/dev/null || echo "unknown")

if [ -f "$WORKSPACE_DIR/memory/$TODAY.md" ]; then
  SIZE=$(wc -c < "$WORKSPACE_DIR/memory/$TODAY.md")
  ok "Today's memory ($TODAY.md): ${SIZE} bytes"
else
  warn "Today's memory file missing: memory/$TODAY.md"
fi

if [ -f "$WORKSPACE_DIR/MEMORY.md" ]; then
  LINES=$(wc -l < "$WORKSPACE_DIR/MEMORY.md")
  if [ "$LINES" -gt 200 ]; then
    warn "MEMORY.md too large: ${LINES} lines (max 200) — run curation"
  else
    ok "MEMORY.md: ${LINES}/200 lines"
  fi
else
  fail "MEMORY.md: MISSING"
fi

for lfile in LEARNINGS.md ERRORS.md; do
  if [ -f "$WORKSPACE_DIR/.learnings/$lfile" ]; then
    ok ".learnings/$lfile: exists"
  else
    warn ".learnings/$lfile: missing — create it"
  fi
done

# --- Config Checks ---
section "CONFIGURATIONS"

# PostIz
POSTIZ_CONFIG="$WORKSPACE_DIR/config/postiz.json"
if [ -f "$POSTIZ_CONFIG" ]; then
  if python3 -c "import json; c=json.load(open('$POSTIZ_CONFIG')); exit(0 if c.get('apiKey','').startswith('POSTIZ') else 1)" 2>/dev/null; then
    warn "PostIz API key not configured: workspace/config/postiz.json"
  else
    ok "PostIz config: API key present"
  fi
else
  warn "PostIz config: missing (workspace/config/postiz.json)"
fi

# OpenClaw JSON
if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
  ok "openclaw.json: exists"
  # Check for placeholder values
  if grep -q "{{" "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
    warn "openclaw.json still has unsubstituted {{PLACEHOLDER}} values"
  fi
else
  fail "openclaw.json: MISSING"
fi

# --- MCP Servers ---
section "MCP SERVERS"
if command -v mcporter &>/dev/null; then
  for server in composio; do
    if mcporter config list 2>/dev/null | grep -q "$server"; then
      ok "MCP server '$server': configured"
    else
      warn "MCP server '$server': not in mcporter config"
    fi
  done
fi

# --- Cost Tracker ---
section "COST TRACKING"
COST_FILE="$WORKSPACE_DIR/ops/cost-tracker.json"
if [ -f "$COST_FILE" ]; then
  TOTAL=$(python3 -c "import json; d=json.load(open('$COST_FILE')); print(d.get('totalCostUSD', 0))" 2>/dev/null || echo "0")
  ok "Cost tracker: exists (total: $TOTAL USD)"
else
  warn "Cost tracker: missing — create workspace/ops/cost-tracker.json"
fi

# --- Summary Report ---
section "SUMMARY"

TOTAL=$((PASS + WARN + FAIL))
log "Results: $PASS pass, $WARN warnings, $FAIL failures (of $TOTAL checks)"

cat > "$REPORT_FILE" << REPORT
# Agent Doctor Report — $(date +%Y-%m-%d)

## Summary
- Pass: $PASS
- Warnings: $WARN
- Failures: $FAIL
- Total checks: $TOTAL

## Status: $([ "$FAIL" -eq 0 ] && echo "HEALTHY" || echo "ISSUES FOUND")

## Issues
$(for issue in "${ISSUES[@]:-}"; do echo "- $issue"; done)

## Full Log
See: $LOG_FILE
REPORT

echo ""
echo "Report saved: $REPORT_FILE"

# Send Telegram if there are failures
if [ "$FAIL" -gt 0 ] && [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  MSG="Agent Doctor — $(date +%Y-%m-%d)
Status: ISSUES FOUND ($FAIL failures, $WARN warnings)

Failures:
$(for issue in "${ISSUES[@]:-}"; do [[ "$issue" == FAIL:* ]] && echo "• $issue"; done)

Full report: $REPORT_FILE"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$MSG" > /dev/null
fi

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

#!/bin/bash
# cost-tracker.sh — OpenClaw API Usage & Cost Metrics
# Tracks token usage and estimated costs by task, session, and agent
# Usage: bash workspace/scripts/cost-tracker.sh [log|report|reset]

set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COST_FILE="$WORKSPACE_DIR/ops/cost-tracker.json"
REPORT_FILE="$WORKSPACE_DIR/ops/cost-report-$(date +%Y-%m-%d).md"

# Model costs per 1M tokens (USD)
declare -A INPUT_COSTS=(
  ["kimi-k2.5"]="0.00"
  ["glm-5"]="0.00"
  ["minimax-m2.5"]="0.00"
  ["minimax-portal/MiniMax-M2.7"]="0.00"
  ["claude-sonnet-4-6"]="3.00"
  ["claude-haiku-4-5"]="0.80"
  ["claude-opus-4-6"]="15.00"
  ["gemini-2.0-flash"]="0.00"
  ["gemini-2.5-flash"]="0.15"
)
declare -A OUTPUT_COSTS=(
  ["kimi-k2.5"]="0.00"
  ["glm-5"]="0.00"
  ["minimax-m2.5"]="0.00"
  ["minimax-portal/MiniMax-M2.7"]="0.00"
  ["claude-sonnet-4-6"]="15.00"
  ["claude-haiku-4-5"]="4.00"
  ["claude-opus-4-6"]="75.00"
  ["gemini-2.0-flash"]="0.00"
  ["gemini-2.5-flash"]="0.60"
)

init_tracker() {
  if [ ! -f "$COST_FILE" ]; then
    mkdir -p "$(dirname "$COST_FILE")"
    python3 -c "
import json, datetime
data = {
  'version': 1,
  'createdAt': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
  'totalCostUSD': 0.0,
  'sessions': [],
  'byAgent': {},
  'byModel': {},
  'byTask': {},
  'limits': {
    'dailyWarningUSD': 5.0,
    'dailyHardLimitUSD': 20.0,
    'monthlyWarningUSD': 50.0
  }
}
json.dump(data, open('$COST_FILE', 'w'), indent=2)
print('Created: $COST_FILE')
"
  fi
}

log_session() {
  # log_session agent model input_tokens output_tokens task_description
  local AGENT="${1:-unknown}"
  local MODEL="${2:-unknown}"
  local INPUT_TOKENS="${3:-0}"
  local OUTPUT_TOKENS="${4:-0}"
  local TASK="${5:-unknown task}"

  local IN_COST="${INPUT_COSTS[$MODEL]:-0.00}"
  local OUT_COST="${OUTPUT_COSTS[$MODEL]:-0.00}"
  local COST=$(python3 -c "print(round(($INPUT_TOKENS * $IN_COST + $OUTPUT_TOKENS * $OUT_COST) / 1000000, 6))")

  python3 - << PYEOF
import json, datetime

with open('$COST_FILE') as f:
    data = json.load(f)

session = {
    'id': len(data['sessions']) + 1,
    'timestamp': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'agent': '$AGENT',
    'model': '$MODEL',
    'inputTokens': $INPUT_TOKENS,
    'outputTokens': $OUTPUT_TOKENS,
    'costUSD': $COST,
    'task': '$TASK'
}
data['sessions'].append(session)
data['totalCostUSD'] = round(data['totalCostUSD'] + $COST, 6)

# By agent
if '$AGENT' not in data['byAgent']:
    data['byAgent']['$AGENT'] = {'sessions': 0, 'totalCostUSD': 0.0, 'totalTokens': 0}
data['byAgent']['$AGENT']['sessions'] += 1
data['byAgent']['$AGENT']['totalCostUSD'] = round(data['byAgent']['$AGENT']['totalCostUSD'] + $COST, 6)
data['byAgent']['$AGENT']['totalTokens'] += $INPUT_TOKENS + $OUTPUT_TOKENS

# By model
if '$MODEL' not in data['byModel']:
    data['byModel']['$MODEL'] = {'sessions': 0, 'totalCostUSD': 0.0}
data['byModel']['$MODEL']['sessions'] += 1
data['byModel']['$MODEL']['totalCostUSD'] = round(data['byModel']['$MODEL']['totalCostUSD'] + $COST, 6)

with open('$COST_FILE', 'w') as f:
    json.dump(data, f, indent=2)

print(f'Logged: {session[\"agent\"]} / {session[\"model\"]} — \${session[\"costUSD\"]:.6f} USD')
PYEOF
}

generate_report() {
  python3 - << PYEOF
import json, datetime

with open('$COST_FILE') as f:
    data = json.load(f)

total = data.get('totalCostUSD', 0)
sessions = data.get('sessions', [])
by_agent = data.get('byAgent', {})
by_model = data.get('byModel', {})

# Today's sessions
today = datetime.date.today().isoformat()
today_sessions = [s for s in sessions if s.get('timestamp', '').startswith(today)]
today_cost = sum(s.get('costUSD', 0) for s in today_sessions)

# This month
month = datetime.date.today().strftime('%Y-%m')
month_sessions = [s for s in sessions if s.get('timestamp', '').startswith(month)]
month_cost = sum(s.get('costUSD', 0) for s in month_sessions)

report = f"""# Cost Report — $(date +%Y-%m-%d)

## Summary
| Period | Sessions | Cost (USD) |
|--------|----------|-----------|
| Today | {len(today_sessions)} | \${today_cost:.4f} |
| This month | {len(month_sessions)} | \${month_cost:.4f} |
| All time | {len(sessions)} | \${total:.4f} |

## By Agent
| Agent | Sessions | Total Cost |
|-------|----------|-----------|
"""
for agent, stats in sorted(by_agent.items(), key=lambda x: x[1]['totalCostUSD'], reverse=True):
    report += f"| {agent} | {stats['sessions']} | \${stats['totalCostUSD']:.4f} |\n"

report += "\n## By Model\n| Model | Sessions | Total Cost |\n|-------|----------|-----------|\n"
for model, stats in sorted(by_model.items(), key=lambda x: x[1]['totalCostUSD'], reverse=True):
    report += f"| {model} | {stats['sessions']} | \${stats['totalCostUSD']:.4f} |\n"

report += "\n## Recent Sessions (last 10)\n| Agent | Model | Task | Cost |\n|-------|-------|------|------|\n"
for s in sessions[-10:]:
    task_preview = s.get('task', '')[:40]
    report += f"| {s.get('agent','-')} | {s.get('model','-')} | {task_preview} | \${s.get('costUSD',0):.6f} |\n"

# Warnings
warnings = []
limits = data.get('limits', {})
if today_cost > limits.get('dailyWarningUSD', 5.0):
    warnings.append(f"Daily cost \${today_cost:.2f} exceeds warning threshold \${limits['dailyWarningUSD']:.2f}")
if month_cost > limits.get('monthlyWarningUSD', 50.0):
    warnings.append(f"Monthly cost \${month_cost:.2f} exceeds warning threshold \${limits['monthlyWarningUSD']:.2f}")

if warnings:
    report += "\n## Warnings\n"
    for w in warnings:
        report += f"- {w}\n"

print(report)
PYEOF
}

CMD="${1:-report}"
case "$CMD" in
  init)
    init_tracker
    ;;
  log)
    init_tracker
    log_session "${2:-}" "${3:-}" "${4:-0}" "${5:-0}" "${6:-unknown}"
    ;;
  report)
    init_tracker
    generate_report | tee "$REPORT_FILE"
    echo ""
    echo "Report saved: $REPORT_FILE"
    ;;
  reset)
    echo "This will reset all cost tracking data. Are you sure? (yes/no)"
    read -r CONFIRM
    if [ "$CONFIRM" = "yes" ]; then
      rm -f "$COST_FILE"
      init_tracker
      echo "Cost tracker reset."
    fi
    ;;
  *)
    echo "Usage: cost-tracker.sh [init|log <agent> <model> <in_tokens> <out_tokens> <task>|report|reset]"
    exit 1
    ;;
esac

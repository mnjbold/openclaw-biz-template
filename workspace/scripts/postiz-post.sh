#!/bin/bash
# postiz-post.sh — Post to LinkedIn via PostIz API
# Usage: ./postiz-post.sh <draft-file> [personal|brand|both]
#
# Draft file must be in workspace/drafts/linkedin-YYYY-MM-DD.md format.
# Config loaded from workspace/config/postiz.json
#
# PostIz API: https://api.postiz.com/public/v1
# Auth: Authorization: {apiKey} header

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$WORKSPACE_DIR/config/postiz.json"
LOG_FILE="$WORKSPACE_DIR/logs/postiz-post.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

fail() {
  log "ERROR: $*"
  echo "FAIL: $*"
  exit 1
}

# --- Args ---
DRAFT_FILE="${1:-}"
TARGET="${2:-personal}"

[[ -z "$DRAFT_FILE" ]] && fail "Usage: postiz-post.sh <draft-file> [personal|brand|both]"
[[ ! -f "$DRAFT_FILE" ]] && fail "Draft file not found: $DRAFT_FILE"
[[ -f "$CONFIG_FILE" ]] || fail "PostIz config not found: $CONFIG_FILE"

# --- Load config ---
API_KEY=$(python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c['apiKey'])")
BASE_URL=$(python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c['baseUrl'])")
CHANNEL_PERSONAL=$(python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c['channels']['personal'])")
CHANNEL_BRAND=$(python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c['channels']['brand'])")

[[ "$API_KEY" == "POSTIZ_API_KEY_HERE" ]] && fail "PostIz API key not configured in $CONFIG_FILE"

# --- Extract post text from draft ---
# Format: optional YAML frontmatter (--- ... ---) then post text then optional --- MEDIA BRIEF ---
# We extract everything between end of frontmatter and the MEDIA BRIEF separator (or EOF)
POST_TEXT=$(python3 - <<'PYEOF'
import sys
import re

with open(sys.argv[1]) as f:
    content = f.read()

# Strip YAML frontmatter if present
if content.startswith('---'):
    parts = content.split('---', 2)
    if len(parts) >= 3:
        content = parts[2].strip()

# Strip MEDIA BRIEF section if present
media_split = re.split(r'\n---\s*\nMEDIA BRIEF', content, flags=re.IGNORECASE)
post_text = media_split[0].strip()

print(post_text)
PYEOF
"$DRAFT_FILE")

[[ -z "$POST_TEXT" ]] && fail "No post text extracted from: $DRAFT_FILE"

log "Draft loaded: $(echo "$POST_TEXT" | wc -c) chars"
log "Target: $TARGET"

# --- Helper: post to a single channel ---
post_to_channel() {
  local channel_id="$1"
  local label="$2"

  log "Posting to $label (channel: $channel_id)..."

  PAYLOAD=$(python3 -c "
import json, sys
data = {
    'type': 'now',
    'content': [
        {
            'content': sys.argv[1],
            'id': sys.argv[2]
        }
    ]
}
print(json.dumps(data))
" "$POST_TEXT" "$channel_id")

  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$BASE_URL/posts" \
    -H "Authorization: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')

  if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "201" ]]; then
    POST_ID=$(echo "$BODY" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id','unknown'))" 2>/dev/null || echo "unknown")
    log "Posted to $label — PostIz ID: $POST_ID"
    echo "OK:$label:$POST_ID"
  else
    log "Failed posting to $label — HTTP $HTTP_CODE: $BODY"
    echo "FAIL:$label:HTTP $HTTP_CODE"
    return 1
  fi
}

# --- Execute based on target ---
RESULTS=()

case "$TARGET" in
  personal)
    RESULTS+=("$(post_to_channel "$CHANNEL_PERSONAL" "personal")")
    ;;
  brand)
    RESULTS+=("$(post_to_channel "$CHANNEL_BRAND" "brand")")
    ;;
  both)
    RESULTS+=("$(post_to_channel "$CHANNEL_PERSONAL" "personal")")
    RESULTS+=("$(post_to_channel "$CHANNEL_BRAND" "brand")")
    ;;
  *)
    fail "Unknown target: $TARGET. Use personal|brand|both"
    ;;
esac

# --- Update draft status ---
DATE_STR=$(basename "$DRAFT_FILE" | grep -oP '\d{4}-\d{2}-\d{2}' || echo "unknown")
META_FILE="$WORKSPACE_DIR/drafts/linkedin-$DATE_STR.meta.json"
if [[ -f "$META_FILE" ]]; then
  python3 -c "
import json
with open('$META_FILE') as f:
    meta = json.load(f)
meta['status'] = 'posted'
meta['postedAt'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
meta['target'] = '$TARGET'
with open('$META_FILE', 'w') as f:
    json.dump(meta, f, indent=2)
print('Meta updated')
"
fi

# --- Summary output ---
echo ""
echo "=== PostIz Post Results ==="
for r in "${RESULTS[@]}"; do
  STATUS=$(echo "$r" | cut -d: -f1)
  LABEL=$(echo "$r" | cut -d: -f2)
  ID=$(echo "$r" | cut -d: -f3)
  if [[ "$STATUS" == "OK" ]]; then
    echo "✓ $LABEL — posted (ID: $ID)"
  else
    echo "✗ $LABEL — $ID"
  fi
done
echo "=========================="

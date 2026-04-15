#!/bin/bash
# bereach.sh — BeReach LinkedIn API Wrapper
# Full CLI wrapper for BeReach unofficial LinkedIn API (https://api.bereach.ai)
# Usage: bash workspace/scripts/bereach.sh <command> [options]
#
# Commands:
#   limits                     Check daily/weekly rate limits
#   search-people              Search LinkedIn profiles
#   visit-profile --url URL    Visit and extract profile data
#   connect --url URL --message MSG    Send connection request
#   message --url URL --message MSG    Send direct message
#   inbox [--limit N]          List inbox conversations
#   invitations                List pending received invitations
#   invitations-sent           List pending sent invitations
#   accept-invitation --id ID  Accept a connection invitation
#   withdraw-invitation --id ID Withdraw a sent invitation
#   crm-add --url URL [--campaign SLUG] [--status STATUS]  Add to CRM
#   state-get --key KEY        Get agent state value
#   state-set --key KEY --value VAL    Set agent state value
#   me                         Get my LinkedIn profile info

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$WORKSPACE_DIR/config/bereach.json"
LOG_FILE="$WORKSPACE_DIR/logs/bereach-$(date +%Y-%m-%d).log"
PIPELINE_FILE="$WORKSPACE_DIR/recruiter/pipeline.json"

API_BASE="https://api.bereach.ai"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$WORKSPACE_DIR/recruiter"

# ── Load config ────────────────────────────────────────────
if [ ! -f "$CONFIG_FILE" ]; then
  echo '{"apiKey": "BEREACH_API_KEY_HERE"}' > "$CONFIG_FILE"
  echo "ERROR: BeReach config not found. Created template at: $CONFIG_FILE"
  echo "Edit it with your API key (brc_...) and re-run."
  exit 1
fi

API_KEY=$(python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c['apiKey'])")

if [ "$API_KEY" = "BEREACH_API_KEY_HERE" ]; then
  echo "ERROR: BeReach API key not configured. Edit $CONFIG_FILE"
  exit 1
fi

# ── Logging ────────────────────────────────────────────────
log() {
  local LEVEL="$1"; shift
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LEVEL] $*" | tee -a "$LOG_FILE"
}

# ── API call helper ────────────────────────────────────────
bereach_get() {
  local ENDPOINT="$1"
  curl -sf \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    "${API_BASE}${ENDPOINT}"
}

bereach_post() {
  local ENDPOINT="$1"
  local PAYLOAD="$2"
  curl -sf \
    -X POST \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "${API_BASE}${ENDPOINT}"
}

# ── Parse args helper ──────────────────────────────────────
get_arg() {
  local KEY="$1"; shift
  local ARGS=("$@")
  local i=0
  while [ $i -lt ${#ARGS[@]} ]; do
    if [ "${ARGS[$i]}" = "$KEY" ]; then
      echo "${ARGS[$((i+1))]}"
      return
    fi
    ((i++))
  done
}

# ── Commands ───────────────────────────────────────────────
CMD="${1:-help}"
shift || true
ARGS=("$@")

case "$CMD" in

  # ── Rate limits ──────────────────────────────────────────
  limits)
    log "INFO" "Checking rate limits"
    RESULT=$(bereach_get "/me/limits")
    echo "$RESULT" | python3 - << 'PYEOF'
import json, sys
d = json.load(sys.stdin)
limits = d.get("limits", {})
print("\n=== BeReach API Limits ===")
for action, info in limits.items():
    daily = info.get("daily") or {}
    weekly = info.get("weekly") or {}
    d_remaining = daily.get("remaining", "N/A")
    d_limit = daily.get("limit", "N/A")
    w_remaining = weekly.get("remaining", "N/A") if weekly else "N/A"
    print(f"  {action:25s}  daily: {d_remaining}/{d_limit}  weekly: {w_remaining}")
credits = d.get("_meta", {}).get("credits", {})
print(f"\n  Credits: {credits.get('remaining','?')}/{credits.get('limit','?')}")
print("========================\n")
PYEOF
    ;;

  # ── My account ───────────────────────────────────────────
  me)
    log "INFO" "Getting my LinkedIn account info"
    bereach_get "/me" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d, indent=2))"
    ;;

  # ── Search people ─────────────────────────────────────────
  search-people)
    TITLE=$(get_arg "--title" "${ARGS[@]}" || echo "")
    LOCATION=$(get_arg "--location" "${ARGS[@]}" || echo "")
    SENIORITY=$(get_arg "--seniority" "${ARGS[@]}" || echo "")
    COMPANY_SIZE=$(get_arg "--company-size" "${ARGS[@]}" || echo "")
    COMPANY=$(get_arg "--company" "${ARGS[@]}" || echo "")
    KEYWORDS=$(get_arg "--keywords" "${ARGS[@]}" || echo "")
    LIMIT=$(get_arg "--limit" "${ARGS[@]}" || echo "20")
    OFFSET=$(get_arg "--offset" "${ARGS[@]}" || echo "0")

    PAYLOAD=$(python3 -c "
import json, sys
p = {'count': int('$LIMIT'), 'start': int('$OFFSET')}
if '$TITLE': p['title'] = '$TITLE'
if '$LOCATION': p['location'] = '$LOCATION'
if '$SENIORITY': p['seniority'] = ['$SENIORITY']
if '$COMPANY_SIZE': p['companySize'] = ['$COMPANY_SIZE']
if '$COMPANY': p['company'] = '$COMPANY'
if '$KEYWORDS': p['keywords'] = '$KEYWORDS'
print(json.dumps(p))
")

    log "INFO" "SEARCH people: title=$TITLE location=$LOCATION limit=$LIMIT"
    RESULT=$(bereach_post "/search/linkedin/people" "$PAYLOAD")

    echo "$RESULT" | python3 - << 'PYEOF'
import json, sys
d = json.load(sys.stdin)
results = d.get("results", d.get("data", []))
total = d.get("paging", {}).get("total", len(results))
print(f"\n=== Search Results ({len(results)} of {total} total) ===")
for i, r in enumerate(results, 1):
    name = r.get("firstName", "") + " " + r.get("lastName", "")
    title = r.get("headline", r.get("title", ""))
    company = r.get("company", {}).get("name", r.get("currentCompany", ""))
    location = r.get("location", "")
    url = r.get("linkedinUrl", r.get("profileUrl", ""))
    degree = r.get("distance", {}).get("value", "?")
    print(f"\n{i:2d}. {name.strip()}")
    print(f"    {title}")
    print(f"    {company} | {location} | {degree}° connection")
    print(f"    {url}")
print()
PYEOF
    log "INFO" "SEARCH complete — returned results"
    ;;

  # ── Visit profile ─────────────────────────────────────────
  visit-profile)
    URL=$(get_arg "--url" "${ARGS[@]}")
    [ -z "$URL" ] && { echo "ERROR: --url required"; exit 1; }

    PAYLOAD=$(python3 -c "import json; print(json.dumps({'profileUrl': '$URL'}))")
    log "INFO" "VISIT profile: $URL"
    RESULT=$(bereach_post "/visit/linkedin/profile" "$PAYLOAD")

    echo "$RESULT" | python3 - << 'PYEOF'
import json, sys
d = json.load(sys.stdin)
profile = d.get("profile", d)
print(f"\n=== Profile: {profile.get('firstName','')} {profile.get('lastName','')} ===")
print(f"  Headline:  {profile.get('headline', '')}")
print(f"  Location:  {profile.get('location', '')}")
print(f"  Degree:    {profile.get('distance', {}).get('value', '?')}° connection")
print(f"  Email:     {profile.get('email', 'N/A')}")
print(f"  Phone:     {profile.get('phone', 'N/A')}")
exp = profile.get("experience", [])
if exp:
    print(f"  Current:   {exp[0].get('title','')} at {exp[0].get('companyName','')}")
    print(f"  Previous:  {', '.join(e.get('companyName','') for e in exp[1:3])}")
print(f"  URL:       {profile.get('profileUrl', profile.get('linkedinUrl', ''))}")
print(f"  Credits used: {d.get('creditsUsed', 0)}")
print()
PYEOF
    log "INFO" "VISIT complete: $URL"
    ;;

  # ── Connect ───────────────────────────────────────────────
  connect)
    URL=$(get_arg "--url" "${ARGS[@]}")
    MESSAGE=$(get_arg "--message" "${ARGS[@]}" || echo "")
    [ -z "$URL" ] && { echo "ERROR: --url required"; exit 1; }

    # Check message length (LinkedIn limit: 300 chars)
    MSG_LEN=${#MESSAGE}
    if [ "$MSG_LEN" -gt 300 ]; then
      echo "ERROR: Connection message too long ($MSG_LEN chars, max 300)"
      exit 1
    fi

    PAYLOAD=$(python3 -c "
import json
p = {'profileUrl': '$URL'}
if '''$MESSAGE''': p['message'] = '''$MESSAGE'''
print(json.dumps(p))
")

    log "SENT" "CONNECT to: $URL | message: ${MESSAGE:0:50}..."
    RESULT=$(bereach_post "/connect/linkedin/profile" "$PAYLOAD")

    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✓ Connection request sent' if d.get('success') else f'✗ Failed: {d.get(\"error\", d)}')"

    # Rate limit: wait 5 seconds between connections
    sleep 5
    ;;

  # ── Message ───────────────────────────────────────────────
  message)
    URL=$(get_arg "--url" "${ARGS[@]}")
    MESSAGE=$(get_arg "--message" "${ARGS[@]}")
    [ -z "$URL" ] && { echo "ERROR: --url required"; exit 1; }
    [ -z "$MESSAGE" ] && { echo "ERROR: --message required"; exit 1; }

    PAYLOAD=$(python3 -c "import json; print(json.dumps({'profileUrl': '$URL', 'message': '''$MESSAGE'''}))")

    log "SENT" "MESSAGE to: $URL | ${MESSAGE:0:50}..."
    RESULT=$(bereach_post "/message/linkedin" "$PAYLOAD")

    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✓ Message sent' if d.get('success') else f'✗ Failed: {d.get(\"error\", d)}')"
    sleep 5
    ;;

  # ── Follow ────────────────────────────────────────────────
  follow)
    URL=$(get_arg "--url" "${ARGS[@]}")
    [ -z "$URL" ] && { echo "ERROR: --url required"; exit 1; }
    PAYLOAD=$(python3 -c "import json; print(json.dumps({'profileUrl': '$URL'}))")
    log "INFO" "FOLLOW: $URL"
    RESULT=$(bereach_post "/follow/linkedin/profile" "$PAYLOAD")
    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✓ Followed' if d.get('success') else f'✗ Failed: {d.get(\"error\", d)}')"
    ;;

  # ── Inbox ─────────────────────────────────────────────────
  inbox)
    LIMIT=$(get_arg "--limit" "${ARGS[@]}" || echo "20")
    PAYLOAD=$(python3 -c "import json; print(json.dumps({'count': $LIMIT}))")
    log "INFO" "INBOX check (limit $LIMIT)"
    RESULT=$(bereach_post "/chats/linkedin" "$PAYLOAD")

    echo "$RESULT" | python3 - << 'PYEOF'
import json, sys
d = json.load(sys.stdin)
convs = d.get("conversations", d.get("data", []))
print(f"\n=== Inbox ({len(convs)} conversations) ===")
for c in convs:
    name = c.get("participant", {}).get("name", "Unknown")
    last_msg = c.get("lastMessage", {}).get("text", "")[:60]
    unread = c.get("unread", False)
    ts = c.get("lastMessage", {}).get("timestamp", "")
    flag = "🔴 UNREAD" if unread else "  "
    print(f"{flag} {name}: {last_msg}")
print()
PYEOF
    ;;

  # ── Invitations ───────────────────────────────────────────
  invitations)
    log "INFO" "INVITATIONS: listing received"
    RESULT=$(bereach_post "/invitations/linkedin" "{}")
    echo "$RESULT" | python3 - << 'PYEOF'
import json, sys
d = json.load(sys.stdin)
invs = d.get("invitations", d.get("data", []))
print(f"\n=== Pending Invitations ({len(invs)}) ===")
for inv in invs:
    name = inv.get("from", {}).get("name", "Unknown")
    title = inv.get("from", {}).get("headline", "")
    inv_id = inv.get("id", "")
    print(f"  {name} | {title} | id: {inv_id}")
print()
PYEOF
    ;;

  invitations-sent)
    log "INFO" "INVITATIONS: listing sent"
    RESULT=$(bereach_post "/invitations/linkedin/sent" "{}")
    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); invs=d.get('invitations',d.get('data',[])); [print(f'  {i.get(\"to\",{}).get(\"name\",\"?\")}: {i.get(\"id\",\"?\")}') for i in invs]; print(f'Total: {len(invs)}')"
    ;;

  accept-invitation)
    INV_ID=$(get_arg "--id" "${ARGS[@]}")
    [ -z "$INV_ID" ] && { echo "ERROR: --id required"; exit 1; }
    PAYLOAD=$(python3 -c "import json; print(json.dumps({'invitationId': '$INV_ID'}))")
    log "INFO" "ACCEPT invitation: $INV_ID"
    RESULT=$(bereach_post "/accept/linkedin/invitation" "$PAYLOAD")
    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✓ Accepted' if d.get('success') else f'✗ Failed: {d}')"
    ;;

  withdraw-invitation)
    INV_ID=$(get_arg "--id" "${ARGS[@]}")
    [ -z "$INV_ID" ] && { echo "ERROR: --id required"; exit 1; }
    PAYLOAD=$(python3 -c "import json; print(json.dumps({'invitationId': '$INV_ID'}))")
    log "INFO" "WITHDRAW invitation: $INV_ID"
    RESULT=$(bereach_post "/withdraw/linkedin/invitation" "$PAYLOAD")
    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✓ Withdrawn' if d.get('success') else f'✗ Failed: {d}')"
    ;;

  # ── CRM operations ────────────────────────────────────────
  crm-add)
    URL=$(get_arg "--url" "${ARGS[@]}")
    CAMPAIGN=$(get_arg "--campaign" "${ARGS[@]}" || echo "")
    STATUS=$(get_arg "--status" "${ARGS[@]}" || echo "searched")
    [ -z "$URL" ] && { echo "ERROR: --url required"; exit 1; }

    PAYLOAD=$(python3 -c "
import json
p = {'linkedinUrl': '$URL', 'status': '$STATUS'}
if '$CAMPAIGN': p['campaign'] = '$CAMPAIGN'
print(json.dumps(p))
")
    log "INFO" "CRM add: $URL campaign=$CAMPAIGN status=$STATUS"
    RESULT=$(bereach_post "/contacts" "$PAYLOAD")
    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✓ Added to CRM' if d.get('success') else f'Result: {d}')"
    ;;

  crm-list)
    CAMPAIGN=$(get_arg "--campaign" "${ARGS[@]}" || echo "")
    PAYLOAD=$(python3 -c "import json; p = {}; exec(\"p['campaign']='$CAMPAIGN'\" if '$CAMPAIGN' else ''); print(json.dumps(p))")
    log "INFO" "CRM list: campaign=$CAMPAIGN"
    RESULT=$(bereach_post "/contacts/campaigns" "$PAYLOAD")
    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d, indent=2))"
    ;;

  # ── Agent state ───────────────────────────────────────────
  state-get)
    KEY=$(get_arg "--key" "${ARGS[@]}")
    [ -z "$KEY" ] && { echo "ERROR: --key required"; exit 1; }
    log "INFO" "STATE get: $KEY"
    bereach_get "/agent-state/$KEY" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('value',''))"
    ;;

  state-set)
    KEY=$(get_arg "--key" "${ARGS[@]}")
    VALUE=$(get_arg "--value" "${ARGS[@]}")
    [ -z "$KEY" ] && { echo "ERROR: --key required"; exit 1; }
    PAYLOAD=$(python3 -c "import json; print(json.dumps({'value': '$VALUE'}))")
    log "INFO" "STATE set: $KEY = $VALUE"
    curl -sf -X PUT \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD" \
      "${API_BASE}/agent-state/$KEY" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✓ Set' if d.get('success') else f'Result: {d}')"
    ;;

  # ── Profile analytics ─────────────────────────────────────
  profile-views)
    log "INFO" "ANALYTICS: profile views"
    RESULT=$(bereach_post "/analytics/linkedin/profile-views" "{}")
    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d, indent=2))"
    ;;

  # ── Pipeline helpers ──────────────────────────────────────
  pipeline-status)
    if [ -f "$PIPELINE_FILE" ]; then
      python3 - << PYEOF
import json
from collections import Counter
with open("$PIPELINE_FILE") as f:
    p = json.load(f)
status_counts = Counter(c.get("status","unknown") for c in p)
print(f"\n=== Pipeline Status ({len(p)} total) ===")
for status, count in sorted(status_counts.items()):
    print(f"  {status:20s}: {count}")
print()
PYEOF
    else
      echo "Pipeline file not found: $PIPELINE_FILE"
    fi
    ;;

  # ── Help ──────────────────────────────────────────────────
  help|*)
    echo ""
    echo "bereach.sh — BeReach LinkedIn API Wrapper"
    echo ""
    echo "Usage: bash workspace/scripts/bereach.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  limits                              Check daily/weekly rate limits"
    echo "  me                                  My LinkedIn account info"
    echo "  search-people [options]             Search LinkedIn profiles"
    echo "    --title STR --location STR --seniority STR --company-size STR"
    echo "    --company STR --keywords STR --limit N --offset N"
    echo "  visit-profile --url URL             Visit profile, extract data"
    echo "  connect --url URL [--message MSG]   Send connection request (max 300 chars)"
    echo "  message --url URL --message MSG     Send direct message"
    echo "  follow --url URL                    Follow without connecting"
    echo "  inbox [--limit N]                   List inbox conversations"
    echo "  invitations                         List received pending invitations"
    echo "  invitations-sent                    List sent pending invitations"
    echo "  accept-invitation --id ID           Accept a received invitation"
    echo "  withdraw-invitation --id ID         Withdraw a sent invitation"
    echo "  crm-add --url URL [--campaign S] [--status S]  Add to BeReach CRM"
    echo "  crm-list [--campaign SLUG]          List CRM contacts"
    echo "  state-get --key KEY                 Get agent persistent state"
    echo "  state-set --key KEY --value VAL     Set agent persistent state"
    echo "  profile-views                       Who viewed your profile"
    echo "  pipeline-status                     Local pipeline summary"
    echo ""
    echo "Config: workspace/config/bereach.json"
    echo "Log:    workspace/logs/bereach-YYYY-MM-DD.log"
    echo ""
    ;;

esac

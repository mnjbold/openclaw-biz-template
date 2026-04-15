# TOOLS.md — Recruiter Agent

## Primary Tool: BeReach API

All LinkedIn operations go through the BeReach API wrapper script.

**Script:** `workspace/scripts/bereach.sh`
**Config:** `workspace/config/bereach.json`
**API Base:** `https://api.bereach.ai`
**Auth:** `Authorization: Bearer brc_...`

---

## Quick Reference — All Commands

### Rate Limits (check FIRST before any batch operation)
```bash
bash workspace/scripts/bereach.sh limits
```
Returns daily/weekly remaining for: connections, messages, profile_visits, scraping

### Search
```bash
# Search people
bash workspace/scripts/bereach.sh search-people \
  --title "Software Engineer" \
  --location "Kuala Lumpur, Malaysia" \
  --seniority "senior" \
  --company-size "51-200" \
  --limit 50

# Search with keywords (Boolean syntax supported)
bash workspace/scripts/bereach.sh search-people \
  --keywords "React OR Vue developer" \
  --location "Remote" \
  --limit 25

# Search by company employees
bash workspace/scripts/bereach.sh search-people \
  --company "Grab" \
  --title "Product Manager" \
  --limit 20
```

Seniority options: `entry`, `associate`, `mid-senior`, `senior`, `director`, `executive`, `partner`
Company size options: `1-10`, `11-50`, `51-200`, `201-500`, `501-1000`, `1001-5000`, `5001-10000`, `10001+`

### Profile Operations
```bash
# Visit profile (extracts full data + contact info)
bash workspace/scripts/bereach.sh visit-profile \
  --url "https://linkedin.com/in/username"

# Visit company page
bash workspace/scripts/bereach.sh visit-company \
  --url "https://linkedin.com/company/companyname"
```

### Outreach
```bash
# Send connection request (max 300 chars message)
bash workspace/scripts/bereach.sh connect \
  --url "https://linkedin.com/in/username" \
  --message "Hi Sarah, your work at Grab on payments infra is impressive. Building something in that space — thought we should connect."

# Send message (must be 1st-degree connection)
bash workspace/scripts/bereach.sh message \
  --url "https://linkedin.com/in/username" \
  --message "Hi Sarah, thanks for connecting! I'm reaching out about a Senior Backend role..."

# Follow without connecting
bash workspace/scripts/bereach.sh follow \
  --url "https://linkedin.com/in/username"
```

### Inbox Management
```bash
# List inbox conversations
bash workspace/scripts/bereach.sh inbox --limit 50

# Search specific conversation
bash workspace/scripts/bereach.sh inbox-search --query "Sarah"

# Read a conversation
bash workspace/scripts/bereach.sh conversation --id "CONV_ID"
```

### Connection/Invitation Management
```bash
# List pending invitations received
bash workspace/scripts/bereach.sh invitations

# List sent invitations (pending)
bash workspace/scripts/bereach.sh invitations-sent

# Accept invitation
bash workspace/scripts/bereach.sh accept-invitation --id "INVITATION_ID"

# Withdraw a sent invitation
bash workspace/scripts/bereach.sh withdraw-invitation --id "INVITATION_ID"
```

### Analytics
```bash
# Who viewed your profile
bash workspace/scripts/bereach.sh profile-views

# Post analytics
bash workspace/scripts/bereach.sh post-analytics --url "POST_URL"
```

### CRM / Pipeline
```bash
# Add candidate to BeReach CRM
bash workspace/scripts/bereach.sh crm-add \
  --url "https://linkedin.com/in/username" \
  --campaign "backend-engineers-q2" \
  --status "connected"

# Update candidate status
bash workspace/scripts/bereach.sh crm-update \
  --url "https://linkedin.com/in/username" \
  --status "warm"

# List campaign contacts
bash workspace/scripts/bereach.sh crm-list --campaign "backend-engineers-q2"
```

### Agent State (persistent key-value store)
```bash
# Save state between sessions
bash workspace/scripts/bereach.sh state-set --key "last_search_offset" --value "50"
bash workspace/scripts/bereach.sh state-get --key "last_search_offset"
```

---

## BeReach API Endpoint Reference

| Operation | Method | Endpoint |
|---|---|---|
| My account | GET | `/me` |
| Rate limits | GET | `/me/limits` |
| People search | POST | `/search/linkedin/people` |
| Company search | POST | `/search/linkedin/companies` |
| Sales Nav people | POST | `/search/linkedin/sales-nav/people` |
| Visit profile | POST | `/visit/linkedin/profile` |
| Visit company | POST | `/visit/linkedin/company` |
| Connect | POST | `/connect/linkedin/profile` |
| Message | POST | `/message/linkedin` |
| Follow | POST | `/follow/linkedin/profile` |
| Inbox list | POST | `/chats/linkedin` |
| Read conversation | POST | `/chats/linkedin/{id}` |
| Inbox search | GET | `/chats/linkedin/search` |
| Invitations received | POST | `/invitations/linkedin` |
| Invitations sent | POST | `/invitations/linkedin/sent` |
| Accept invitation | POST | `/accept/linkedin/invitation` |
| Withdraw invitation | POST | `/withdraw/linkedin/invitation` |
| Collect post likes | POST | `/collect/linkedin/likes` |
| Collect comments | POST | `/collect/linkedin/comments` |
| Profile views | POST | `/analytics/linkedin/profile-views` |
| Publish post | POST | `/publish/linkedin/post` |
| CRM upsert | POST | `/contacts` |
| CRM campaigns | POST | `/contacts/campaigns` |
| Agent state | GET/PUT | `/agent-state/{key}` |

---

## Model Assignment

- Search + planning: `opencode-go/kimi-k2.5` (strategic)
- Message composition: `opencode-go/glm-5` (creative/natural)
- Pipeline updates + reporting: `opencode-go/minimax-m2.5` (fast/mechanical)
- Complex multi-step operations: `claude-sonnet-4-6` via claude-automation agent

---

## Rate Limit Quick Reference

| Action | Daily | Weekly | Min Interval |
|---|---|---|---|
| Connection requests | 30 | 200 | 5s |
| Messages | 100 | 400 | 5s |
| Profile visits | 350 | 1750 | 2s |
| Scraping/search | 300 | — | 2s |
| Posts | 3 | — | 5s |
| Credits | 200 | — | — |

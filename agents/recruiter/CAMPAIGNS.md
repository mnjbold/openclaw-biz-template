# CAMPAIGNS.md — Recruiter Campaign Definitions

Each campaign is a targeted outreach effort for a specific role or talent pool.
Store campaign configs here. Run them with the recruiter agent or directly via bereach.sh.

---

## Active Campaign Format

```json
{
  "id": "campaign-slug",
  "name": "Human Readable Name",
  "role": "Job Title Being Recruited For",
  "status": "active|paused|completed",
  "startDate": "YYYY-MM-DD",
  "targetCount": 100,
  "searchCriteria": {
    "title": "Software Engineer",
    "location": "Kuala Lumpur, Malaysia",
    "seniority": "senior",
    "companySize": "51-200",
    "keywords": "React Node.js"
  },
  "messageTemplate": {
    "connectionNote": "Hi {{firstName}}, impressed by your {{skill}} work at {{company}}. Building a team in that space — let's connect.",
    "firstMessage": "Hi {{firstName}}, I'm looking for a Senior Engineer to join our product team. Your background in {{skill}} is exactly what we need. Open to a quick chat?",
    "followUp1": "Hi {{firstName}}, just circling back — we're still actively hiring and thought this might be relevant timing for you.",
    "followUp2": "Hey {{firstName}}, sharing this insight on the space we're building in case it's useful: [INSIGHT]. Happy to share more on a call."
  },
  "pipeline": {
    "beachCampaign": "campaign-slug",
    "targetStatus": "connection_sent"
  },
  "metrics": {
    "searched": 0,
    "visited": 0,
    "connectionSent": 0,
    "connected": 0,
    "messaged": 0,
    "warm": 0,
    "meetings": 0
  }
}
```

---

## Example Campaigns

### Backend Engineers KL
```json
{
  "id": "backend-kl-2026-q2",
  "name": "Backend Engineers Kuala Lumpur",
  "role": "Senior Backend Engineer",
  "status": "active",
  "searchCriteria": {
    "title": "Backend Engineer OR Software Engineer",
    "location": "Kuala Lumpur, Malaysia",
    "seniority": "mid-senior",
    "keywords": "Go OR Python OR Node.js"
  }
}
```

### Product Managers (Remote)
```json
{
  "id": "pm-remote-2026-q2",
  "name": "Product Managers Remote",
  "role": "Senior Product Manager",
  "status": "active",
  "searchCriteria": {
    "title": "Product Manager",
    "location": "Remote",
    "seniority": "senior",
    "companySize": "51-200"
  }
}
```

---

## Running a Campaign

```bash
# Start a new search batch for a campaign
bash workspace/scripts/bereach.sh search-people \
  --title "Senior Backend Engineer" \
  --location "Kuala Lumpur, Malaysia" \
  --seniority "mid-senior" \
  --limit 30

# Visit top candidates (validate before outreach)
bash workspace/scripts/bereach.sh visit-profile --url "LINKEDIN_URL"

# Send connection request
bash workspace/scripts/bereach.sh connect \
  --url "LINKEDIN_URL" \
  --message "Hi [Name], your backend work at [Company] is impressive — building a similar team here, let's connect."

# Add to CRM
bash workspace/scripts/bereach.sh crm-add \
  --url "LINKEDIN_URL" \
  --campaign "backend-kl-2026-q2" \
  --status "connection_sent"
```

## Telling the Agent to Run a Campaign

Message your agent:
```
Run the backend-kl-2026-q2 campaign. Search 30 candidates today, visit top 20, 
connect to best 15 with personalized notes based on their actual profile.
Check limits first, stay 5 below the daily cap.
```

The agent will:
1. Check limits
2. Search candidates
3. Visit each profile
4. Personalize connection note using actual profile data
5. Send connections (spaced 5s apart)
6. Add all to pipeline
7. Report to Telegram

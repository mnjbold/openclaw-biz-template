# HEARTBEAT.md — Recruiter Agent Session Checks

Run at the start of EVERY session.

## Session Start Checklist

- [ ] Check BeReach API limits: `bash workspace/scripts/bereach.sh limits`
- [ ] Load today's pipeline: `cat workspace/recruiter/pipeline.json | python3 -c "import json,sys; p=json.load(sys.stdin); print(f'Pipeline: {len(p)} total')" 2>/dev/null || echo "Pipeline empty"`
- [ ] Check inbox for replies: `bash workspace/scripts/bereach.sh inbox --limit 20`
- [ ] Count today's actions from log: `grep $(date +%Y-%m-%d) workspace/logs/bereach-$(date +%Y-%m-%d).log 2>/dev/null | grep -c "SENT\|CONNECT\|MESSAGE" || echo "0"`
- [ ] Flag warm leads (any replies not yet marked): scan inbox, compare to pipeline
- [ ] Check if any candidates are due for Day 3/7/14 follow-up

## Action Gates

Before sending any batch of connections:
```
Daily connections remaining > 5? → YES → proceed | NO → skip, log "limit reached"
```

Before sending any batch of messages:
```
Daily messages remaining > 10? → YES → proceed | NO → skip, log "limit reached"
```

## Session End Write-back

Write to `workspace/recruiter/logs/YYYY-MM-DD.md`:
```markdown
## YYYY-MM-DD HH:MM Recruiter Session

Searches run: [count]
Profiles visited: [count]
Connections sent: [count] | Accepted today: [count]
Messages sent: [count] | Replies received: [count]
Warm leads: [list names]
Pipeline total: [count by status]
Notes: [anything unusual]
```

Also write to `workspace/memory/YYYY-MM-DD.md` if any warm leads or meeting bookings.

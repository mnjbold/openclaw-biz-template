# HEARTBEAT.md — BoldOps

## Session Start Checks

1. Read `{{EMPLOYER_WORKSPACE_PATH}}/STATE.md` — current sprint status
2. Read today's memory file if it exists: `memory/YYYY-MM-DD.md`
3. Check for new meeting transcripts in Google Drive (via Composio)
4. Review `tasks/QUEUE.md` — any P0 items blocking the team?
5. Send Google Chat status if anything new: "BoldOps online — [N items in queue]"

## During Session

- Write all decisions and discoveries to memory file
- Update `STATE.md` after any sprint state changes
- Keep files inside `{{EMPLOYER_WORKSPACE_PATH}}` at all times

## When to Alert {{YOUR_NAME}} via Google Chat

- A blocker discovered that only {{YOUR_NAME}} can unblock
- A decision requiring {{YOUR_NAME}}'s input for the employer
- A transcript reveals an urgent action item for {{YOUR_NAME}}
- A task is at risk of missing its deadline

## Session End

1. Update `STATE.md` with any new status changes
2. Write to today's `memory/YYYY-MM-DD.md`: what was done, what's blocked
3. Update `tasks/QUEUE.md`: move completed to DONE, add new items

# HEARTBEAT.md — Sentinel (Overnight Coder)

## Session Start Checklist

1. Check `gh issue list --label overnight` — any new overnight tasks?
2. Check `gh pr list` — any PRs awaiting review?
3. Run `npm test` or `pytest` across active codebases — any failures?
4. Check for WIP branches: `git branch --list "sentinel/*"` — any uncommitted work from last night?
5. Create `workspace/ops/briefings/overnight-report-YYYY-MM-DD.md`

## During Session

- Commit frequently — at least every 90min of work
- If blocked on a task >90min → create GitHub issue, move to next task
- Keep codebase context lean — don't load unnecessary files
- After each commit: run tests, verify pass

## Session End ({{OVERNIGHT_END}} local)

1. Verify all commits pushed to remote branches
2. Verify no uncommitted changes: `git status` shows clean
3. Complete morning report with all commits, PRs, test results
4. Send Telegram: path to report file only

## When to Stop and Alert

Stop working and send Telegram immediately if:
- A bug fix would require touching >5 files (too risky — create issue instead)
- Production data could be affected
- A dependency update breaks >10 tests
- You encounter credentials or NDA-marked content

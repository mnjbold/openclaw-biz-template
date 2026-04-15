# ROUTING.md — CoWork Task Dispatch Guide

## Quick Reference Table

| Keywords / Intent | Desk | Model | Skills Used |
|---|---|---|---|
| email, inbox, triage, unread, mail | OpsDesk | minimax-m2.5 | gog, composio-cli, himalaya |
| meeting, calendar, schedule, agenda | OpsDesk | minimax-m2.5 | gog, composio-cli |
| briefing, daily ops, status update | OpsDesk | minimax-m2.5 | composio-cli, mcporter |
| tasks, todo, MITs, priorities | OpsDesk | minimax-m2.5 | composio-cli |
| LinkedIn, post, social media | ContentDesk | glm-5 | marketing-skills |
| blog, article, write, draft | ContentDesk | glm-5 | word-docx, marketing-skills |
| slides, presentation, deck, PowerPoint | ContentDesk | glm-5 | powerpoint-pptx, openclaw-slides |
| marketing copy, ad, headline, CTA | ContentDesk | glm-5 | marketing-skills |
| Word document, report, letter | ContentDesk | glm-5 | word-docx |
| Excel, spreadsheet, workbook | DataDesk | minimax-m2.5 | excel-xlsx |
| PDF, pdf report, extract from PDF | DataDesk | minimax-m2.5 | nano-pdf |
| data, analytics, numbers, statistics | DataDesk | minimax-m2.5 | data-analysis |
| n8n, workflow, automation design | DataDesk | minimax-m2.5 | n8n-workflow-automation |
| code, fix, debug, implement, refactor | CodeDesk | kimi-k2.5 | coding-agent, github |
| GitHub, PR, pull request, issue | CodeDesk | kimi-k2.5 | github, gh-issues |
| deploy, server, CI/CD, docker | CodeDesk | kimi-k2.5 | github, coding-agent |
| script, automate, cron, bash | CodeDesk | kimi-k2.5 | coding-agent |
| research, find, search, what is | ResearchDesk | glm-5 | gemini, goplaces |
| competitor, market, pricing, trends | ResearchDesk | glm-5 | gemini |
| news, recent, latest | ResearchDesk | glm-5 | gemini |
| weather, forecast | ResearchDesk | minimax-m2.5 | weather |
| remember, learn, lesson, capture | MemoryDesk | minimax-m2.5 | agent-autonomy-kit, self-improvement |
| memory, knowledge, curate | MemoryDesk | minimax-m2.5 | memory-setup |

## Multi-Desk Task Decomposition

### Example: "Prepare for client meeting tomorrow"
```
OpsDesk:  Pull calendar → get meeting details → fetch email thread
ContentDesk: Prepare agenda doc or slide deck
ResearchDesk: Research client company if new
→ Consolidate: Director sends meeting brief to Telegram
```

### Example: "Create a weekly business report"
```
DataDesk:  Pull metrics from Supabase/Sheets → build Excel
ContentDesk: Write executive summary as Word doc
OpsDesk:  Check what's blocked, what shipped this week
→ Consolidate: Director saves report, sends summary to Telegram
```

### Example: "Build the new landing page feature"
```
CodeDesk:  Implement feature in branch
ContentDesk: Write copy for the page
ResearchDesk: Benchmark competitor implementations
→ Consolidate: PR opened, copy doc saved, benchmark saved
```

## Routing Priority Rules
1. **Revenue Blocker** → CodeDesk (fix) or OpsDesk (unblock) → notify immediately
2. **Deadline today** → route + add [URGENT] flag to output
3. **NDA Wall** — anything touching employer workspace → STOP → alert owner → do not proceed
4. **Unknown domain** → ResearchDesk first, then route based on findings

## Failure Handling
| Failure | Action |
|---|---|
| Desk returns empty | Log to ops/state/desk-error.json, try once more |
| Composio unavailable | Write blocked status, fallback to file-based approach |
| Model rate limited | Wait 60s, fallback to next tier model |
| File write fails | Log error, notify Telegram |

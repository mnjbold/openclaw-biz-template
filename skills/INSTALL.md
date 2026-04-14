# Skills — Installation Guide

Skills extend your agents with specialized capabilities. They inject a `SKILL.md` into the agent's system prompt, giving it domain knowledge and step-by-step workflows for specific tasks.

## Pre-installed in This Template

These skills are already included in this template and configured as presets in `openclaw.json`:

| Skill | Version | What It Does |
|---|---|---|
| `word-docx` | 1.0.2 | Generate Word documents via Python python-docx |
| `excel-xlsx` | 1.0.2 | Generate Excel spreadsheets via Python openpyxl |
| `powerpoint-pptx` | 1.0.1 | Generate PowerPoint presentations |
| `nano-pdf` | 1.0.0 | Edit and create PDF files |
| `data-analysis` | 1.0.2 | Data analysis, visualization, Pandas workflows |
| `github` | 1.0.0 | GitHub PR/issue workflows, branch management |
| `marketing-skills` | 0.1.2 | LinkedIn copywriting, content strategy |
| `memory-setup` | 1.0.0 | Memory system bootstrapping and maintenance |
| `agent-autonomy-kit` | 1.0.0 | Agent self-improvement, AnalogAgent loop |
| `superdesign` | 1.0.0 | UI/UX design generation and prototyping |

## Installing New Skills

Skills are installed from [clawhub.ai](https://clawhub.ai) (5,147+ curated skills):

```bash
# Search for skills
clawhub search "google sheets"
clawhub search "slack notifications"

# Install a skill
openclaw skill install <skill-slug>

# Or install specific version
openclaw skill install <skill-slug>@1.2.0

# List installed skills
openclaw plugins list
```

## Top Skills to Consider

From clawhub.ai rankings:

| Skill | Downloads | Purpose |
|---|---|---|
| `google-workspace-cli` | 117k | Gmail, Calendar, Drive CLI |
| `slack-bot` | 89k | Slack integration |
| `notion-sync` | 72k | Notion database sync |
| `jira-integration` | 61k | Jira issue management |
| `hubspot-crm` | 45k | HubSpot CRM workflows |
| `stripe-billing` | 38k | Stripe subscription management |
| `airtable-ops` | 31k | Airtable base operations |
| `n8n-workflow-automation` | 28k | n8n workflow builder |
| `seo-writer` | 24k | SEO-optimized content |
| `social-scheduler` | 21k | Multi-platform social posting |

## Creating Custom Skills

Add a skill to `skills/<skill-name>/`:

**`skills/my-skill/SKILL.md`:**
```markdown
# My Custom Skill

## When to Use
Describe when agents should activate this skill.

## Step-by-Step Process
1. First step
2. Second step
3. Validation check

## Examples
[Concrete examples here]

## Tools Required
- Tool 1
- Tool 2

## Output Format
[Expected output format]
```

**Register in `openclaw.json`:**
```json
"skills": {
  "presets": ["my-skill"]
}
```

## Skill Scoping

Limit skills to specific agents by adding to the agent definition in `openclaw.json`:
```json
{
  "id": "code-desk",
  "skills": ["github", "data-analysis"],
  ...
}
```

## Updating Skills

```bash
openclaw skill update <skill-slug>
openclaw skill update --all
```

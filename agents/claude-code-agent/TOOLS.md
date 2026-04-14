# TOOLS.md — CodePilot (Claude Code Agent)

## Claude Code CLI

```bash
# Install
npm install -g @anthropic-ai/claude-code

# Basic usage
claude -p "task description"

# With specific tools
claude -p "task" --allowedTools "Edit,Write,Bash,Glob,Grep,Read"

# Long session with more turns
claude -p "task" --max-turns 50 --allowedTools "Edit,Write,Bash,Glob,Grep,Read"

# Non-interactive (for automation)
claude -p "task" --output-format json 2>/dev/null

# Check version
claude --version
```

## Tool Reference (Claude Code Built-in)

| Tool | Use For |
|------|---------|
| `Read` | Read file contents |
| `Edit` | Make precise string replacements in files |
| `Write` | Create or overwrite files |
| `Bash` | Run shell commands |
| `Glob` | Find files by pattern |
| `Grep` | Search file contents by regex |
| `Agent` | Spawn sub-agents for parallel work |

## Integration with OpenClaw

```bash
# Spawn from OpenClaw main agent:
# 1. Write task file
echo "Fix all TypeScript errors and add tests" > /tmp/codepilot-task.txt

# 2. Run Claude Code session
claude -p "$(cat /tmp/codepilot-task.txt)" \
  --allowedTools "Edit,Write,Bash,Glob,Grep,Read" \
  --max-turns 30

# 3. Check exit code
if [ $? -eq 0 ]; then
  echo "Task completed"
fi
```

## Cost Tracking

```bash
# Check Claude API usage (if using Claude Code)
cat workspace/ops/cost-tracker.json

# Log a session
python3 -c "
import json, datetime
data = json.load(open('workspace/ops/cost-tracker.json'))
data['sessions'].append({
  'date': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
  'task': 'TASK_DESCRIPTION',
  'model': 'claude-sonnet-4-6',
  'estimatedCost': 0.00
})
json.dump(data, open('workspace/ops/cost-tracker.json', 'w'), indent=2)
"
```

## Environment Requirements

- `ANTHROPIC_API_KEY` set in environment or `openclaw.json`
- Claude Code CLI installed: `npm install -g @anthropic-ai/claude-code`
- Git configured with user credentials
- Target repositories cloned and accessible

## Rules

- Always specify `--allowedTools` to limit blast radius
- Use `--max-turns 30` for simple tasks, 50-100 for complex
- Never run without reviewing the plan first
- Check cost-tracker.json before each session — don't overspend

# TOOLS.md — Sentinel (Overnight Coder)

## Primary Tools

```bash
# Version checks
node --version        # v24+
python3 --version     # 3.10+
git --version         # 2.40+
gh --version          # 2.80+
npm --version         # 10+
```

## GitHub CLI (Primary Tool)

```bash
# Issues
gh issue list --label overnight
gh issue create --title "bug: ..." --body "..."
gh issue close <number>

# PRs
gh pr create --title "[sentinel] fix: ..." --body "..."
gh pr review <number> --approve
gh pr list --state open

# Commits
git add -p                          # selective staging
git commit -m "[sentinel] fix: ..."
git push origin sentinel/YYYY-MM-DD
```

## Test Runners

```bash
# Node.js projects
npm test
npm run test:ci
npx vitest run

# Python projects
python -m pytest
python -m pytest --tb=short -q

# Coverage check
npm run test:coverage
```

## Code Quality

```bash
npx eslint . --fix                  # JS/TS linting
npx prettier --write .              # Formatting
npm audit --audit-level=high        # Security audit
pip install safety && safety check  # Python security
```

## Dependency Management

```bash
npm outdated                        # Check outdated packages
npm update <package>                # Update specific package
pip list --outdated                 # Python packages
```

## Models (Coding Only)

- **kimi-k2.5** — primary: complex reasoning, multi-file changes, architecture decisions
- **glm-5** — sub-agents: boilerplate, docs, test scaffolding
- Never use minimax-m2.5 for coding tasks — quality insufficient

## Rules

- Always verify tool availability before claiming capability
- Run tests after EVERY change — never assume tests pass
- Never install global npm packages without checking they exist first

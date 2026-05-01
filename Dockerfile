# ============================================================
# Bold Business OpenClaw Enterprise - Full Scale Multi-Agent
# Dockerfile for Fly.io deployment
# Features: OpenClaw gateway, Computer Use (Xvfb+Chromium),
#           FastAPI Dashboard, PostgreSQL client, Claude Code,
#           Multi-agent support, Supervisor process manager
# ============================================================

FROM node:20-bookworm-slim

# ---- Labels ----
LABEL maintainer="Bold Business <mnjbold>" \
      description="OpenClaw Enterprise Multi-Agent Gateway" \
      version="1.0.0"

# ---- System dependencies ----
# Computer Use: Xvfb + Chromium + VNC
# Dashboard: Python3 + pip
# Database: PostgreSQL client
# Utilities: curl, git, supervisor
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    curl wget git ca-certificates gnupg \
    # Python for dashboard (installer/app.py)
    python3 python3-pip python3-venv \
    # Computer Use - display & browser
    xvfb x11vnc chromium fluxbox \
    xdotool scrot imagemagick \
    # Process supervisor
    supervisor \
    # PostgreSQL client
    postgresql-client \
    # Build essentials
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# ---- Install pnpm ----
RUN npm install -g pnpm@latest

# ---- Install OpenClaw globally ----
RUN npm install -g @openclaw/cli@latest

# ---- Install Claude Code CLI ----
RUN npm install -g @anthropic-ai/claude-code@latest 2>/dev/null || true

# ---- Python dependencies for dashboard ----
RUN pip3 install --no-cache-dir --break-system-packages \
    fastapi uvicorn[standard] pydantic requests python-dotenv

# ---- Set working directory ----
WORKDIR /app

# ---- Copy repo contents ----
COPY . .

# ---- Create persistent data directories ----
RUN mkdir -p \
    /data/openclaw \
    /data/workspaces \
    /data/db \
    /data/logs \
    /data/dashboard \
    /data/agents

# ---- Copy workspace configs to /data (will be overridden by volume mount) ----
RUN cp -r /app/workspace/. /data/openclaw/ 2>/dev/null || true && \
    cp -r /app/agents/. /data/agents/ 2>/dev/null || true && \
    cp -r /app/config/. /data/openclaw/config/ 2>/dev/null || true && \
    cp -r /app/skills/. /data/openclaw/skills/ 2>/dev/null || true

# ---- Supervisor configuration ----
RUN mkdir -p /etc/supervisor/conf.d

COPY docker/supervisord.conf /etc/supervisor/supervisord.conf

# ---- Environment variables ----
ENV NODE_ENV=production \
    OPENCLAW_PREFER_PNPM=1 \
    OPENCLAW_STATE_DIR=/data/openclaw \
    NODE_OPTIONS=--max-old-space-size=4096 \
    DISPLAY=:99 \
    PYTHONUNBUFFERED=1 \
    DASHBOARD_PORT=8181 \
    GATEWAY_PORT=3000

# ---- Expose ports ----
# 3000: OpenClaw gateway (main)
# 8181: FastAPI dashboard
EXPOSE 3000 8181

# ---- Entrypoint ----
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

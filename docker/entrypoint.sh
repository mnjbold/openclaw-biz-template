#!/bin/bash
set -e

echo "========================================"
echo " Bold Business OpenClaw Enterprise"
echo " Multi-Agent Gateway - Starting..."
echo "========================================"

# ---- Initialize data directory from bundled defaults ----
if [ ! -f /data/openclaw/openclaw.json ]; then
  echo "[init] First boot: copying default workspace configs..."
  cp -rn /app/workspace/. /data/openclaw/ 2>/dev/null || true
  cp -rn /app/agents/. /data/agents/ 2>/dev/null || true
  cp -rn /app/config/. /data/openclaw/config/ 2>/dev/null || true
  cp -rn /app/skills/. /data/openclaw/skills/ 2>/dev/null || true

  # Copy openclaw.json template if provided
  if [ -f /app/openclaw.json.template ] && [ -n "$OPENCLAW_API_KEY" ]; then
    echo "[init] Configuring openclaw.json from template..."
    cp /app/openclaw.json.template /data/openclaw/openclaw.json
    sed -i "s|__API_KEY__|${OPENCLAW_API_KEY}|g" /data/openclaw/openclaw.json
    sed -i "s|__GATEWAY_TOKEN__|${OPENCLAW_GATEWAY_TOKEN:-$(openssl rand -hex 32)}|g" /data/openclaw/openclaw.json
  fi
fi

# ---- Start virtual display for Computer Use ----
echo "[display] Starting Xvfb virtual display..."
Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp &
XVFB_PID=$!
export DISPLAY=:99
sleep 1
echo "[display] Xvfb started (PID $XVFB_PID)"

# ---- Start window manager for Computer Use ----
fluxbox -display :99 &>/dev/null &

# ---- Start VNC server (optional, for debugging) ----
if [ "${ENABLE_VNC:-false}" = "true" ]; then
  echo "[vnc] Starting x11vnc on port 5900..."
  x11vnc -display :99 -nopw -forever -bg -quiet
fi

# ---- Start FastAPI Dashboard ----
echo "[dashboard] Starting FastAPI dashboard on port ${DASHBOARD_PORT:-8181}..."
cd /app
python3 installer/app.py &
DASHBOARD_PID=$!
echo "[dashboard] Dashboard started (PID $DASHBOARD_PID)"

# ---- Start OpenClaw Gateway (main process) ----
echo "[gateway] Starting OpenClaw gateway on port ${GATEWAY_PORT:-3000}..."
exec openclaw gateway \
  --allow-unconfigured \
  --port ${GATEWAY_PORT:-3000} \
  --bind lan \
  --state-dir /data/openclaw

#!/bin/bash
set -Eeuo pipefail
CDP_PORT=9222
INTERNAL_PORT=9223
PROFILE_DIR="/data/chromium-profile"
mkdir -p "$PROFILE_DIR"
chmod 0700 "$PROFILE_DIR"

CHROMIUM="$(find /ms-playwright -type f -name chrome -print -quit 2>/dev/null)"
if [[ -z "$CHROMIUM" ]]; then
  echo "[ERROR] Chromium executable not found" >&2
  exit 1
fi

CDP_HOST="$(hostname)"
cat > /tmp/ote-nginx.conf <<EOF
worker_processes 1;
error_log /dev/stderr warn;
pid /tmp/ote-nginx.pid;
events { worker_connections 1024; }
http {
  access_log /dev/stdout;
  map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
  }
  server {
    listen ${CDP_PORT};
    location / {
      proxy_pass http://127.0.0.1:${INTERNAL_PORT};
      proxy_http_version 1.1;
      proxy_set_header Host localhost;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection \$connection_upgrade;
      proxy_read_timeout 86400s;
      proxy_send_timeout 86400s;
      sub_filter_types application/json text/plain;
      sub_filter_once off;
      sub_filter 'ws://localhost/' 'ws://${CDP_HOST}:${CDP_PORT}/';
      sub_filter 'ws://127.0.0.1:${INTERNAL_PORT}/' 'ws://${CDP_HOST}:${CDP_PORT}/';
    }
  }
}
EOF

echo "[INFO] Persistent Chromium profile: $PROFILE_DIR"
echo "[INFO] Internal CDP address: http://${CDP_HOST}:${CDP_PORT}"
echo "[WARN] Unauthenticated CDP: never expose this port to the internet"

"$CHROMIUM" \
  --headless \
  --no-sandbox \
  --disable-setuid-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port="$INTERNAL_PORT" \
  --remote-allow-origins="*" \
  --user-data-dir="$PROFILE_DIR" \
  --no-first-run \
  --no-default-browser-check \
  --disable-background-networking \
  --disable-default-apps \
  --disable-sync \
  --password-store=basic \
  --use-mock-keychain \
  about:blank &
CHROME_PID=$!

cleanup() {
  kill "$CHROME_PID" "${NGINX_PID:-}" 2>/dev/null || true
  wait "$CHROME_PID" "${NGINX_PID:-}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

READY=0
for i in $(seq 1 40); do
  if ! kill -0 "$CHROME_PID" 2>/dev/null; then
    echo "[ERROR] Chromium exited during startup" >&2
    exit 1
  fi
  if curl -fsS "http://127.0.0.1:${INTERNAL_PORT}/json/version" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 1
done
if (( READY != 1 )); then
  echo "[ERROR] Chromium did not become ready" >&2
  exit 1
fi

nginx -g "daemon off;" -c /tmp/ote-nginx.conf &
NGINX_PID=$!
echo "[INFO] OTE Browser CDP ready"
while true; do
  kill -0 "$CHROME_PID" 2>/dev/null || { echo "[ERROR] Chromium stopped" >&2; exit 1; }
  kill -0 "$NGINX_PID" 2>/dev/null || { echo "[ERROR] nginx stopped" >&2; exit 1; }
  sleep 5
done

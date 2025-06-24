#!/bin/bash

# Start Chromium with remote debugging on internal port
/ms-playwright/chromium-1169/chrome-linux/chrome \
  --headless \
  --disable-gpu \
  --disable-dev-shm-usage \
  --disable-features=VizDisplayCompositor \
  --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port=9223 \
  --no-sandbox \
  --disable-web-security &

# Wait for Chrome to start
sleep 3

# Forward external port 9222 to Chrome's internal port 9223
socat TCP-LISTEN:9222,bind=0.0.0.0,fork TCP:127.0.0.1:9223 &

# Wait for background processes
wait
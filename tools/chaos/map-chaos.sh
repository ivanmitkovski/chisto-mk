#!/usr/bin/env bash
# Local chaos smoke: toggle Redis / proxy (requires toxiproxy + compose).
set -euo pipefail
echo "Add toxiproxy latency to redis upstream (example — adapt to your compose service names)."
# toxiproxy-cli toxic add -t latency -a latency=500 redis_proxy

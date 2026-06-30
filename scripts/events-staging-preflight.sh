#!/usr/bin/env bash
# Optional staging/dev API smoke before Flutter integration tests.
# Uses the same base URL as mobile --dart-define=API_URL (no path prefix).
set -euo pipefail

api_base="${INTEGRATION_TEST_API_URL:-${API_URL:-}}"
if [[ -z "${api_base// }" ]]; then
  echo "events-staging-preflight: no INTEGRATION_TEST_API_URL or API_URL set; skipping."
  exit 0
fi

base="${api_base%/}"
echo "events-staging-preflight: GET ${base}/health/ready"

if ! curl -fsS "${base}/health/ready" >/dev/null; then
  echo "events-staging-preflight: /health/ready failed" >&2
  exit 1
fi

echo "events-staging-preflight: OK (database readiness)"
echo "Reminder: multi-instance chat requires REDIS_URL + ALB idle timeout >= 300s (docs/event-chat-runbook.md)."

#!/usr/bin/env bash
# Build release artifacts for TestFlight / Play internal testing.
# Usage: ./scripts/build-beta.sh [ios|android|both]
set -euo pipefail

cd "$(dirname "$0")/.."

PLATFORM="${1:-both}"
EXTRA_DEFINES=()

if [[ -n "${SENTRY_DSN:-}" ]]; then
  EXTRA_DEFINES+=(--dart-define="SENTRY_DSN=${SENTRY_DSN}")
fi

if [[ -n "${SENTRY_ENVIRONMENT:-}" ]]; then
  EXTRA_DEFINES+=(--dart-define="SENTRY_ENVIRONMENT=${SENTRY_ENVIRONMENT}")
else
  EXTRA_DEFINES+=(--dart-define=SENTRY_ENVIRONMENT=beta)
fi

COMMON=(
  --release
  --dart-define=ENV=staging
  "${EXTRA_DEFINES[@]}"
)

flutter pub get

case "$PLATFORM" in
  ios)
    flutter build ipa "${COMMON[@]}"
    ;;
  android)
    flutter build appbundle "${COMMON[@]}"
    ;;
  both)
    flutter build ipa "${COMMON[@]}"
    flutter build appbundle "${COMMON[@]}"
    ;;
  *)
    echo "Usage: $0 [ios|android|both]" >&2
    exit 1
    ;;
esac

echo "Done. Upload IPA/AAB via TestFlight / Play internal testing (see apps/mobile/README.md)."

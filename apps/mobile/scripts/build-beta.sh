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

# Optional build number / name overrides. App Store Connect requires each
# upload's build number to exceed the previous one for the same version, but
# iOS defaults to pubspec's `+N`. Pass BUILD_NUMBER (and optionally BUILD_NAME)
# to bump it without editing pubspec, e.g. `BUILD_NUMBER=10 ./scripts/build-beta.sh ios`.
if [[ -n "${BUILD_NUMBER:-}" ]]; then
  COMMON+=(--build-number="${BUILD_NUMBER}")
fi
if [[ -n "${BUILD_NAME:-}" ]]; then
  COMMON+=(--build-name="${BUILD_NAME}")
fi

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

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ENV="${ENV:-prod}"
SENTRY_DSN="${SENTRY_DSN:-}"
EXTRA_DEFINES=(
  "--dart-define=ENV=${ENV}"
  "--dart-define=SITE_HISTORY_TAB_ENABLED=true"
)
if [[ -n "${SENTRY_DSN}" ]]; then
  EXTRA_DEFINES+=("--dart-define=SENTRY_DSN=${SENTRY_DSN}")
fi

echo "Building iOS IPA (release, ENV=${ENV})..."
flutter build ipa --release "${EXTRA_DEFINES[@]}"

echo "Building Android App Bundle (release, ENV=${ENV})..."
flutter build appbundle --release "${EXTRA_DEFINES[@]}"

echo "Done. Upload IPA/AAB via App Store Connect / Play Console."

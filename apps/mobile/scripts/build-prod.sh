#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Optional local overrides (gitignored): SENTRY_DSN, ANDROID_* signing vars.
if [[ -f .env.release ]]; then
  # shellcheck disable=SC1091
  set -a
  source .env.release
  set +a
fi

# Default to the machine-local upload keystore created by setup-android-signing.sh.
if [[ -z "${ANDROID_KEYSTORE_PATH:-}" && -f "${HOME}/.chisto/android-signing.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "${HOME}/.chisto/android-signing.env"
  set +a
fi

ENV="${ENV:-prod}"
SENTRY_DSN="${SENTRY_DSN:-}"
EXTRA_DEFINES=(
  "--dart-define=ENV=${ENV}"
  "--dart-define=SITE_HISTORY_TAB_ENABLED=true"
)
if [[ -n "${SENTRY_DSN}" ]]; then
  EXTRA_DEFINES+=("--dart-define=SENTRY_DSN=${SENTRY_DSN}")
else
  echo "WARNING: SENTRY_DSN is unset — prod builds will not report crashes to Sentry." >&2
  echo "         Set SENTRY_DSN in apps/mobile/.env.release or your shell before building." >&2
fi

if [[ -z "${ANDROID_KEYSTORE_PATH:-}" ]]; then
  echo "ERROR: ANDROID_KEYSTORE_PATH is required for a Play Store release AAB." >&2
  echo "       Run: ./scripts/setup-android-signing.sh" >&2
  echo "       Or set ANDROID_KEYSTORE_* in apps/mobile/.env.release" >&2
  exit 1
fi
for var in ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: ${var} is required when ANDROID_KEYSTORE_PATH is set." >&2
    exit 1
  fi
done

echo "Building iOS IPA (release, ENV=${ENV})..."
flutter build ipa --release "${EXTRA_DEFINES[@]}"

echo "Building Android App Bundle (release, ENV=${ENV}, signed)..."
flutter build appbundle --release "${EXTRA_DEFINES[@]}"

echo "Verifying Android release signature..."
KEYTOOL="${KEYTOOL:-}"
if [[ -z "${KEYTOOL}" ]]; then
  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/keytool" ]]; then
    KEYTOOL="${JAVA_HOME}/bin/keytool"
  elif [[ -x "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" ]]; then
    KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
  fi
fi
if [[ -n "${KEYTOOL}" ]]; then
  if "${KEYTOOL}" -printcert -jarfile build/app/outputs/bundle/release/app-release.aab 2>&1 | grep -q "Android Debug"; then
    echo "ERROR: AAB is signed with the Android Debug certificate. Check ANDROID_KEYSTORE_*." >&2
    exit 1
  fi
  echo "Android AAB signing looks OK (not debug)."
else
  echo "WARNING: keytool not found; skipped AAB signing verification." >&2
fi

echo "Done."
echo "  iOS IPA:  build/ios/ipa/*.ipa"
echo "  Android:  build/app/outputs/bundle/release/app-release.aab"
echo "  Upload via Transporter / Play Console (see apps/mobile/docs/store-release.md)."

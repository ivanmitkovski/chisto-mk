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
  AAB="build/app/outputs/bundle/release/app-release.aab"
  if "${KEYTOOL}" -printcert -jarfile "${AAB}" 2>&1 | grep -q "Android Debug"; then
    echo "ERROR: AAB is signed with the Android Debug certificate. Check ANDROID_KEYSTORE_*." >&2
    exit 1
  fi
  KEYSTORE_SHA1="$("${KEYTOOL}" -list -v \
    -keystore "${ANDROID_KEYSTORE_PATH}" \
    -alias "${ANDROID_KEY_ALIAS}" \
    -storepass "${ANDROID_KEYSTORE_PASSWORD}" 2>/dev/null \
    | awk -F': ' '/SHA1:/ {print $2; exit}')"
  AAB_SHA1="$("${KEYTOOL}" -printcert -jarfile "${AAB}" 2>/dev/null \
    | awk -F': ' '/SHA1:/ {print $2; exit}')"
  echo "Upload keystore SHA1: ${KEYSTORE_SHA1:-unknown}"
  echo "AAB certificate SHA1: ${AAB_SHA1:-unknown}"
  if [[ -n "${KEYSTORE_SHA1}" && -n "${AAB_SHA1}" && "${KEYSTORE_SHA1}" != "${AAB_SHA1}" ]]; then
    echo "ERROR: AAB certificate does not match the configured upload keystore." >&2
    exit 1
  fi
  if [[ -n "${PLAY_EXPECTED_UPLOAD_SHA1:-}" ]]; then
    EXPECTED="$(echo "${PLAY_EXPECTED_UPLOAD_SHA1// /}" | tr '[:lower:]' '[:upper:]')"
    ACTUAL="$(echo "${AAB_SHA1// /}" | tr '[:lower:]' '[:upper:]')"
    if [[ "${ACTUAL}" != "${EXPECTED}" ]]; then
      echo "ERROR: AAB upload cert SHA1 (${AAB_SHA1}) does not match Play Console." >&2
      echo "       Expected: ${PLAY_EXPECTED_UPLOAD_SHA1}" >&2
      echo "       Use the original upload .jks from Play → Setup → App signing." >&2
      exit 1
    fi
    echo "Upload cert matches Play Console (PLAY_EXPECTED_UPLOAD_SHA1)."
  fi
  echo "Android AAB signing looks OK (not debug)."
else
  echo "WARNING: keytool not found; skipped AAB signing verification." >&2
fi

echo "Done."
echo "  iOS IPA:  build/ios/ipa/*.ipa"
echo "  Android:  build/app/outputs/bundle/release/app-release.aab"
echo "  Upload via Transporter / Play Console (see apps/mobile/docs/store-release.md)."

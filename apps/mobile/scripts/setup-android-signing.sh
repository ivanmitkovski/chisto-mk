#!/usr/bin/env bash
# Create (once) a local Android upload keystore for Play Console uploads.
# Credentials are stored in ~/.chisto/android-signing.env (mode 600). Never commit.
set -euo pipefail

KEYSTORE="${HOME}/.chisto/chisto-upload.jks"
ENV_FILE="${HOME}/.chisto/android-signing.env"
ALIAS="chisto-upload"

KEYTOOL="${KEYTOOL:-}"
if [[ -z "${KEYTOOL}" ]]; then
  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/keytool" ]]; then
    KEYTOOL="${JAVA_HOME}/bin/keytool"
  elif [[ -x "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" ]]; then
    KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
  else
    echo "ERROR: keytool not found. Install Android Studio or set KEYTOOL." >&2
    exit 1
  fi
fi

mkdir -p "${HOME}/.chisto"

if [[ -f "${KEYSTORE}" ]]; then
  echo "Upload keystore already exists: ${KEYSTORE}"
else
  PASS="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"
  "${KEYTOOL}" -genkeypair -v \
    -keystore "${KEYSTORE}" \
    -alias "${ALIAS}" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "${PASS}" -keypass "${PASS}" \
    -dname "CN=Chisto.mk, OU=Mobile, O=EKOHAB Skopje, L=Skopje, ST=Skopje, C=MK"
  printf 'export ANDROID_KEYSTORE_PATH=%s\nexport ANDROID_KEYSTORE_PASSWORD=%s\nexport ANDROID_KEY_ALIAS=%s\nexport ANDROID_KEY_PASSWORD=%s\n' \
    "${KEYSTORE}" "${PASS}" "${ALIAS}" "${PASS}" > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  echo "Created upload keystore: ${KEYSTORE}"
  echo "Saved credentials: ${ENV_FILE}"
fi

echo
echo "Upload certificate SHA-256 (for assetlinks.json / Play upload key):"
"${KEYTOOL}" -list -v \
  -keystore "${KEYSTORE}" \
  -alias "${ALIAS}" \
  -storepass "$(grep ANDROID_KEYSTORE_PASSWORD "${ENV_FILE}" | cut -d= -f2-)" \
  | grep "SHA256:" || true

echo
echo "After enrolling Play App Signing, add the Play *app signing* SHA-256 to"
echo "apps/landing/public/.well-known/assetlinks.json (keep the upload key too)."

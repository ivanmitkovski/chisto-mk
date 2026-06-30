#!/usr/bin/env bash
# Fetch prod DB password from Secrets Manager (on demand; not used by prod-db-tunnel.sh).
# Requires AWS CLI credentials with secretsmanager:GetSecretValue on the app secret.
set -euo pipefail

REGION="${AWS_REGION:-eu-central-1}"
SECRET_ID="${SECRET_ID:-chisto/production/api}"

fetch_password() {
  aws secretsmanager get-secret-value \
    --secret-id "$SECRET_ID" \
    --region "$REGION" \
    --query 'SecretString' \
    --output text \
    | python3 -c "import sys,json,urllib.parse; d=json.load(sys.stdin); print(urllib.parse.unquote(urllib.parse.urlparse(d['DATABASE_URL']).password), end='')"
}

if [[ "${PRINT_PASSWORD:-}" == "1" ]]; then
  fetch_password
  echo ""
  exit 0
fi

if [[ "${COPY_PASSWORD:-}" == "1" ]]; then
  password="$(fetch_password)"
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$password" | pbcopy
    echo "Password copied to clipboard (not printed)."
    exit 0
  fi
  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$password" | xclip -selection clipboard
    echo "Password copied to clipboard (not printed)."
    exit 0
  fi
  echo "No clipboard tool found (pbcopy/xclip). Use PRINT_PASSWORD=1 in a private session."
  exit 1
fi

echo "Usage (run in a separate terminal from prod-db-tunnel.sh):"
echo "  COPY_PASSWORD=1 $0    # recommended — copies to clipboard, does not print"
echo "  PRINT_PASSWORD=1 $0   # prints to terminal (avoid in shared or recorded sessions)"
exit 0

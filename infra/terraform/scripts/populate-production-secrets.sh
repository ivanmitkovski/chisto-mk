#!/usr/bin/env bash
# Populate chisto/production/api Secrets Manager JSON from a local env file.
# NEVER commit production env files. Never echo secret values.
set -euo pipefail

REGION="${AWS_REGION:-eu-central-1}"
SECRET_NAME="${SECRET_NAME:-chisto/production/api}"
ENV_FILE="${1:-}"

if [[ -z "$ENV_FILE" || ! -f "$ENV_FILE" ]]; then
  echo "Usage: SECRET_NAME=chisto/production/api $0 /path/to/production.env"
  echo "File must contain KEY=value lines for secrets listed in .env.production.example"
  exit 1
fi

declare -A SECRETS=()
REQUIRED_KEYS=(
  DATABASE_URL
  JWT_SECRET
  CHAT_ENCRYPTION_KEY
  CHECK_IN_QR_SECRET
  SITE_SHARE_TOKEN_SECRET
  METRICS_BEARER_TOKEN
  REDIS_URL
  TWILIO_AUTH_TOKEN
  TWILIO_ACCOUNT_SID
  TWILIO_MESSAGING_SERVICE_SID
  POSTMARK_SERVER_TOKEN
  POSTMARK_WEBHOOK_BASIC_PASS
  FIREBASE_SERVICE_ACCOUNT_JSON
)

while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  key="${key#"${key%%[![:space:]]*}"}"
  key="${key%"${key##*[![:space:]]}"}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  value="${value#\"}"
  value="${value%\"}"
  SECRETS["$key"]="$value"
done < "$ENV_FILE"

missing=()
for key in "${REQUIRED_KEYS[@]}"; do
  if [[ -z "${SECRETS[$key]:-}" ]]; then
    missing+=("$key")
  fi
done

if ((${#missing[@]} > 0)); then
  echo "Missing required keys in $ENV_FILE:"
  printf '  - %s\n' "${missing[@]}"
  exit 1
fi

JSON='{'
first=1
for key in "${REQUIRED_KEYS[@]}"; do
  val="${SECRETS[$key]}"
  escaped=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' <<<"$val")
  if [[ $first -eq 0 ]]; then JSON+=','; fi
  first=0
  JSON+="\"${key}\":${escaped}"
done
JSON+='}'

echo "==> Updating secret $SECRET_NAME (values not printed)"
aws secretsmanager put-secret-value \
  --region "$REGION" \
  --secret-id "$SECRET_NAME" \
  --secret-string "$JSON" >/dev/null

echo "==> Done. Redeploy ECS to pick up new secret values."

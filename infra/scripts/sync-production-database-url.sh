#!/usr/bin/env bash
# Sync DATABASE_URL in chisto/production/api from the RDS-managed master password secret.
# Normally automated by the chisto-prod-rds-password-sync Lambda (EventBridge rotation
# event + 15-minute reconciliation). Use this script for manual recovery when ECS tasks
# fail with P1000 / 28P01.
set -euo pipefail

REGION="${AWS_REGION:-eu-central-1}"
APP_SECRET_ID="${APP_SECRET_ID:-chisto/production/api}"
DB_IDENTIFIER="${DB_IDENTIFIER:-chisto-prod}"

RDS_SECRET_ARN=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --region "$REGION" \
  --query 'DBInstances[0].MasterUserSecret.SecretArn' \
  --output text)

if [[ -z "$RDS_SECRET_ARN" || "$RDS_SECRET_ARN" == "None" ]]; then
  echo "ERROR: RDS instance $DB_IDENTIFIER has no MasterUserSecret (manage_master_user_password disabled?)"
  exit 1
fi

read -r DB_HOST DB_PORT DB_NAME <<<"$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --region "$REGION" \
  --query 'DBInstances[0].[Endpoint.Address,Endpoint.Port,DBName]' \
  --output text)"

echo "==> Building DATABASE_URL from RDS managed secret (values not printed)"
export REGION RDS_SECRET_ARN APP_SECRET_ID DB_HOST DB_PORT DB_NAME
NEW_DATABASE_URL=$(python3 <<'PY'
import json
import os
import subprocess
import urllib.parse

region = os.environ["REGION"]
rds_secret_arn = os.environ["RDS_SECRET_ARN"]
app_secret_id = os.environ["APP_SECRET_ID"]
host = os.environ["DB_HOST"]
port = os.environ["DB_PORT"]
dbname = os.environ["DB_NAME"]

rds_raw = subprocess.check_output(
    [
        "aws", "secretsmanager", "get-secret-value",
        "--secret-id", rds_secret_arn,
        "--region", region,
        "--query", "SecretString",
        "--output", "text",
    ],
    text=True,
)
rds = json.loads(rds_raw)
username = rds["username"]
password = rds["password"]

app_raw = subprocess.check_output(
    [
        "aws", "secretsmanager", "get-secret-value",
        "--secret-id", app_secret_id,
        "--region", region,
        "--query", "SecretString",
        "--output", "text",
    ],
    text=True,
)
app = json.loads(app_raw)

encoded_password = urllib.parse.quote(password, safe="")
app["DATABASE_URL"] = (
    f"postgresql://{username}:{encoded_password}@{host}:{port}/{dbname}?sslmode=require"
)

print(json.dumps(app))
PY
)

echo "==> Updating app secret $APP_SECRET_ID"
aws secretsmanager put-secret-value \
  --region "$REGION" \
  --secret-id "$APP_SECRET_ID" \
  --secret-string "$NEW_DATABASE_URL" >/dev/null

echo "==> Done. Redeploy ECS (force-new-deployment) so tasks pick up the new DATABASE_URL."

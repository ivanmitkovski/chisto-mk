#!/usr/bin/env bash
# Port-forward prod RDS to localhost for TablePlus / psql.
# Requires: AWS CLI v2, Session Manager plugin, credentials for eu-central-1.
set -euo pipefail

REGION="${AWS_REGION:-eu-central-1}"
LOCAL_PORT="${LOCAL_PORT:-15432}"
BASTION_NAME="${BASTION_NAME:-chisto-prod-db-bastion}"
RDS_HOST="${RDS_HOST:-chisto-prod.cfs2eqk4qbnk.eu-central-1.rds.amazonaws.com}"

if ! command -v session-manager-plugin >/dev/null 2>&1; then
  echo "Session Manager plugin not found."
  echo "Install: brew install --cask session-manager-plugin"
  echo "Or user-local: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
  exit 1
fi

INSTANCE_ID="$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=${BASTION_NAME}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)"

if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]]; then
  echo "No running bastion (${BASTION_NAME}). Launch one in the prod VPC with SSM (AmazonSSMManagedInstanceCore)."
  exit 1
fi

echo "Bastion: ${INSTANCE_ID}"
echo "Tunnel: 127.0.0.1:${LOCAL_PORT} -> ${RDS_HOST}:5432"
echo ""
echo "TablePlus (while this script runs):"
echo "  Host:     127.0.0.1"
echo "  Port:     ${LOCAL_PORT}"
echo "  User:     chisto"
echo "  Database: chisto_prod"
echo "  SSL:      require"
echo ""
echo "Password: run in another terminal (clipboard, not printed):"
echo "  COPY_PASSWORD=1 ./infra/scripts/prod-db-password.sh"
echo ""
echo "Press Ctrl+C to close the tunnel."
echo ""

exec aws ssm start-session \
  --target "$INSTANCE_ID" \
  --region "$REGION" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"${RDS_HOST}\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"${LOCAL_PORT}\"]}"

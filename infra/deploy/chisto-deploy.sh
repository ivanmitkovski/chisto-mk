#!/usr/bin/env bash
# Box-side deploy. The only thing the CI key can invoke: it is pinned as a forced
# command in the deploy user's authorized_keys, so an ssh session with that key
# runs this and nothing else, whatever it asks for. See README.md.
#
# Lives at /srv/chisto/chisto-deploy.sh, alongside the compose file and .env it
# operates on. Installed root:root 0755, which stops the deploy user editing this
# file's contents — but not replacing it, since the directory is deploy-owned and
# that is what governs deletion. Moot either way: deploy is in the docker group,
# which is root-equivalent. The boundary that holds is the forced command, which
# gives the CI key no shell and therefore no way to write anything.
#
# Argument arrives as SSH_ORIGINAL_COMMAND, i.e. fully attacker-controlled if the
# key ever leaks. Validated below before it touches anything.
set -euo pipefail

STACK_DIR=/srv/chisto
ENV_FILE="$STACK_DIR/.env"
HEALTH_URL=http://127.0.0.1/health/ready
HEALTH_TRIES=45          # x2s = 90s. Cold start pulls no images and runs migrations.

ref="${SSH_ORIGINAL_COMMAND:-}"

# Digest-pinned refs to our own package, nothing else. This single regex is the
# security boundary: it rejects shell metacharacters, other registries, and
# mutable tags in one go. Deploying a tag would also defeat the point — the digest
# is what makes the deployed bytes identical to the smoke-tested ones.
if [[ ! "$ref" =~ ^ghcr\.io/ivanmitkovski/chisto-api@sha256:[0-9a-f]{64}$ ]]; then
  echo "refusing: expected ghcr.io/ivanmitkovski/chisto-api@sha256:<64 hex>, got '${ref}'" >&2
  exit 2
fi

echo "==> deploying ${ref}"

# Recorded before anything changes, so the rollback below has somewhere to go.
previous="$(sed -n 's/^API_IMAGE=//p' "$ENV_FILE" | head -1)"

# Explicit, and before compose is involved: docker-compose.yml still carries a
# build: section that an override cannot remove, and there is no source tree here.
# Once the image is local, Compose uses it and never considers building.
docker pull "$ref"

set_image() {
  local image="$1" tmp
  tmp="$(mktemp)"
  grep -v '^API_IMAGE=' "$ENV_FILE" > "$tmp" || true
  echo "API_IMAGE=${image}" >> "$tmp"
  # .env holds credentials in the production overlay; do not widen its mode.
  chmod 600 "$tmp"
  mv "$tmp" "$ENV_FILE"
}

set_image "$ref"

cd "$STACK_DIR"
# Not a rolling restart — expect a few seconds of downtime. The one-shot migrate
# service is a depends_on of api, so `prisma migrate deploy` runs here, before the
# new API starts.
docker compose up -d

echo "==> waiting for ${HEALTH_URL}"
for _ in $(seq 1 "$HEALTH_TRIES"); do
  if curl -fsS --max-time 5 "$HEALTH_URL" 2>/dev/null | grep -q '"status":"ok"'; then
    echo "==> healthy: ${ref}"
    exit 0
  fi
  sleep 2
done

echo "!! ${HEALTH_URL} never came up" >&2
docker compose logs --tail 50 api >&2 || true

# Image-only rollback. Migrations already applied by the step above are NOT
# reversed — prisma migrate deploy has no down path — so if this deploy crossed a
# migration boundary the old image may not run against the new schema. Rolling
# back is a best effort to leave the box serving; it is not a substitute for
# someone reading the logs above.
if [[ -n "$previous" && "$previous" != "$ref" ]]; then
  echo "==> rolling back to ${previous}" >&2
  set_image "$previous"
  docker compose up -d || true
fi

exit 1

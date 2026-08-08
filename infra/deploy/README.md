# Automated deploy to the VPS

CI builds and publishes the image; this is the last hop. A `deploy` job in
[`api-deploy.yml`](../../.github/workflows/api-deploy.yml) makes **one** ssh call
carrying a digest-pinned image ref. The box's `authorized_keys` pins that key to
[`chisto-deploy.sh`](chisto-deploy.sh) as a forced command, so the key cannot open a
shell, run anything else, or `scp` — it can request a deploy, and that is all.

```
push to infra-migration → build → push to GHCR → smoke-test the pulled image
   (or workflow_dispatch)                          ↓
                          ssh deploy@vps "ghcr.io/…@sha256:…"
                                              ↓
                    forced command → chisto-deploy.sh → pull, up -d, /health/ready
```

Deploy runs on pushes to `infra-migration` and on manual dispatch. `develop` and
`main` build but do not deploy — after this branch merges, that condition is the
one to revisit.

**The GHCR package is public**, so the box needs no `docker login` and no PAT. The
image bakes no secrets — `.dockerignore` excludes `.env*` and the only
credential-shaped `ENV` in `Dockerfile.prod` is a dummy Prisma build URL — and the
repo is public, so there is nothing the image discloses that the source does not.

**What this does not do.** The forced command blocks `scp`, so `docker-compose.yml`,
`infra/Caddyfile` and `.env` are still copied by hand. That is a deliberate
consequence of the design, not an oversight: only the image is automated.

**Scope of the restriction.** The deploy user needs the `docker` group, and the
docker group is root-equivalent on any box. The forced command constrains what a
*leaked CI key* can do — one script, no shell. It is not a sandbox around the
script itself, which is why the script is owned by root and not writable by the
deploy user.

## One-time setup on the box

```bash
# 1. The stack moves out of a personal home directory so a service user owns it.
sudo mkdir -p /srv/chisto
sudo mv ~/chisto/docker-compose.yml ~/chisto/.env /srv/chisto/
sudo mkdir -p /srv/chisto/infra && sudo mv ~/chisto/infra/Caddyfile /srv/chisto/infra/

# 2. Service user: no sudo, no login shell of its own worth having, docker group.
sudo useradd --system --create-home --shell /bin/bash deploy
sudo usermod -aG docker deploy
sudo chown -R deploy:deploy /srv/chisto
sudo chmod 600 /srv/chisto/.env

# 3. The script, owned by root so deploy cannot rewrite its own forced command.
sudo install -o root -g root -m 0755 chisto-deploy.sh /usr/local/bin/chisto-deploy.sh
```

Generate the key **on your laptop**, not on the box — the private half goes to
GitHub and the box never needs it:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/chisto_deploy -C "github-actions-deploy" -N ""
```

Install the public half with the forced command and every capability stripped:

```bash
sudo -u deploy mkdir -p /home/deploy/.ssh
sudo -u deploy tee /home/deploy/.ssh/authorized_keys >/dev/null <<'EOF'
command="/usr/local/bin/chisto-deploy.sh",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty,restrict ssh-ed25519 AAAA… github-actions-deploy
EOF
sudo -u deploy chmod 600 /home/deploy/.ssh/authorized_keys
```

Everything before the key type is the restriction. `command=` is what makes the
requested command land in `SSH_ORIGINAL_COMMAND` and be ignored; `restrict` denies
all forwarding, including anything added in future OpenSSH versions.

## Repository secrets

Under **Settings → Secrets and variables → Actions → New repository secret**.

These are repo-wide rather than environment-scoped, because creating an
environment needs repo admin. Fork PRs still cannot read them — GitHub withholds
secrets from fork-triggered runs. Move them to an environment (and add a required
reviewer) if admin becomes available.

| Secret | Value |
|---|---|
| `VPS_HOST` | `159.195.212.221` |
| `VPS_USER` | `deploy` |
| `VPS_SSH_KEY` | contents of `~/.ssh/chisto_deploy` (the private half, whole file including header and trailer) |
| `VPS_KNOWN_HOSTS` | output of `ssh-keyscan -t ed25519 159.195.212.221` |

Read `VPS_KNOWN_HOSTS` off the box's own `/etc/ssh/ssh_host_ed25519_key.pub` if you
want to be strict — `ssh-keyscan` trusts whatever answers on the network, which is
the assumption pinning exists to remove.

## Verify before trusting it

From your laptop, with the private key. These prove the restriction, not the happy
path, and are worth running in this order:

```bash
# Refused — forced command ignores what you asked for, script rejects the empty ref
ssh -i ~/.ssh/chisto_deploy deploy@<host> "bash"          # exit 2
ssh -i ~/.ssh/chisto_deploy deploy@<host>                 # exit 2, no shell
ssh -i ~/.ssh/chisto_deploy deploy@<host> "ghcr.io/ivanmitkovski/chisto-api:sha-b9d89ae"   # exit 2, tags refused

# Accepted
ssh -i ~/.ssh/chisto_deploy deploy@<host> "ghcr.io/ivanmitkovski/chisto-api@sha256:<64 hex>"
```

Then run the workflow from the Actions tab and check it reaches the same result.

## Rollback

The script rolls the **image** back on its own if `/health/ready` does not come up,
and fails the run. Migrations are not rolled back — `prisma migrate deploy` has no
down path — so a deploy that crossed a migration boundary may leave the previous
image unable to run against the new schema. The automatic rollback is there to keep
the box serving where it can, not to make migrations reversible.

Manual equivalent, if you need it:

```bash
ssh -i ~/.ssh/chisto_deploy deploy@<host> "ghcr.io/ivanmitkovski/chisto-api@sha256:<previous digest>"
```

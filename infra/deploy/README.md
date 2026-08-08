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
`infra/Caddyfile`, `.env` — and this script itself — are still copied by hand. That is
a deliberate consequence of the design, not an oversight: only the image is automated.

The copy on the box does not track the repo. After editing `chisto-deploy.sh` here:

```bash
scp infra/deploy/chisto-deploy.sh chisto:/tmp/
ssh -t chisto 'sudo install -o root -g root -m 0755 /tmp/chisto-deploy.sh /srv/chisto/chisto-deploy.sh'
```

**Scope of the restriction — read this before trusting it further than it goes.**

The restriction lives on the **key**, not on the account. `authorized_keys` carries one
entry per key and each can pin its own `command=`, so `deploy` is a powerful account
that nobody logs into, while GitHub authenticates *as* it and reaches only one script.

| | |
|---|---|
| What the **CI key** can do | Run `chisto-deploy.sh` with one valid image digest. No shell, no file writes, no reading `.env` |
| What the **account** can do | Own `/srv/chisto`, read `.env`, and — via the `docker` group — anything root can |

Root-owning the script is thinner than it looks. It stops `deploy` editing the file's
contents, but `/srv/chisto` is deploy-owned, and directory write permission is what
governs deleting and replacing a file. So a shell as `deploy` can swap the script out.
That changes nothing in practice, because the `docker` group is already
root-equivalent — `docker run --privileged -v /:/host` ends the discussion. Anyone with
code execution as `deploy` owns the box, and rewriting this script is the least
interesting thing available to them.

Which leaves exactly one boundary that carries weight: **the CI key can only ask for a
deploy of a specific image.** That one holds.

## One-time setup on the box

Everything lives in one directory:

```
/srv/chisto/
  docker-compose.yml
  .env                  600, deploy — written by the deploy script
  chisto-deploy.sh      0755 root:root — deploy runs it; see the caveat above
  infra/Caddyfile
```

`/srv` rather than a home directory is not tidiness. `/home/<user>` is mode `700`, so
a service user cannot traverse into it at all; keeping the stack there would mean
loosening someone's home to `711` and giving `deploy` write access inside it.

```bash
# 1. Stack directory, out of any personal home.
sudo mkdir -p /srv/chisto/infra
# scp docker-compose.yml -> /srv/chisto/ and infra/Caddyfile -> /srv/chisto/infra/

# 2. Service user: no sudo, docker group.
sudo useradd --system --create-home --shell /bin/bash deploy
sudo usermod -aG docker deploy
sudo chown -R deploy:deploy /srv/chisto
sudo chmod 600 /srv/chisto/.env

# 3. The script, root-owned. Costs nothing; see the caveat above about what it
#    does and does not buy.
sudo install -o root -g root -m 0755 chisto-deploy.sh /srv/chisto/chisto-deploy.sh
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
command="/srv/chisto/chisto-deploy.sh",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty,restrict ssh-ed25519 AAAA… github-actions-deploy
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

## A deploy starts the box, and leaves it started

Worth stating because it is easy to forget between sessions: **a push that touches
`apps/api/**` or the workflow brings the box up and leaves it up.** While the rehearsal
stack runs the base compose file it is `NODE_ENV=development` with
`OTP_DEV_RETURN_CODE=true`, so OTP codes come back in the HTTP response and anyone who
finds the address can register.

Take it down when you are not actively using it:

```bash
ssh chisto 'docker compose -p chisto down'     # never -v: the volumes are the data
```

Phase C removes the concern — the production overlay sets `NODE_ENV=production` and
`OTP_DEV_RETURN_CODE=false`, at which point staying up is the desired behaviour.

## What a deploy actually costs

Observed on run #108, both attempts:

| | |
|---|---|
| Build, cold cache | ~8m53s |
| Build, warm cache | ~1m37s |
| Deploy job | 26–56s, mostly the image pull |
| Containers restarted | **`api` only** — postgres, redis, minio and caddy are untouched |

`docker compose up -d` recreates just the services whose definition changed, so the
data services stay up across a deploy. The one-shot `migrate` service re-runs each
time and exits; `api` waits on it.

## Digests are not stable across rebuilds

Rebuilding the same commit produces a **different digest**, which looks alarming and
is not. Two builds of the same tree:

```
b88c18b5  created 2026-08-08T09:35:39Z  revision b9d89aef
886a35a7  created 2026-08-08T11:48:38Z  revision dbdb45b8
```

Identical layers — same count, same content hashes. Only the config differs, because
`docker/metadata-action` stamps `created` and `revision` into it, and the config is
part of the digest.

This does not weaken digest pinning: the digest still names exactly the artifact that
was smoke-tested in that run, which is the guarantee worth having. It does mean **a
changed digest is not evidence that the code changed** — compare `revision`, or the
layer hashes, if that is the question you are asking.

## The workflow does not trigger on changes to this directory

`api-deploy.yml` filters on `apps/api/**` and itself, not `infra/deploy/**`. Editing
`chisto-deploy.sh` therefore builds and deploys nothing — correct, because CI cannot
ship this script anyway; the forced command blocks the scp that would. Adding the path
would only produce builds that change nothing on the box.

To exercise the pipeline without a code change, use **Re-run all jobs** on a previous
run. That replays the workflow file from that commit and needs no push. Manual
dispatch also works in principle, but while `main` still carries the old AWS workflow
with its required `environment` input, the dispatch form renders from the default
branch and can reject the call.

## Residual risks

Recorded because they are obvious now and invisible in six months. Ranked by how
likely they are, not by how bad they sound.

**1. Repo write access means production code execution.** Anyone who can push to a
deploying branch gets their code built and shipped. Not a flaw in this design — it is
what continuous deployment is — and by a wide margin the most realistic path in.

**2. A leaked CI key can force a downgrade.** The regex accepts *any* digest under
`ghcr.io/ivanmitkovski/chisto-api`, including old ones. An attacker with the key cannot
run arbitrary code, but can choose which of your images runs — reintroducing a patched
vulnerability, or deploying something broken to cause an outage. **Worth closing before
the box holds production data**, and cheap when you do: have the script refuse a digest
older than the one currently deployed, or check the ref against the branch's latest
build before accepting it.

**3. A shell as `deploy` is root.** Requires a separate vulnerability to get there. The
`docker` group is the reason it escalates. Fixing it properly means rootless Docker,
which is a larger change than this migration should absorb, and nearly every
Compose-based deploy has the same property.

**Not exposed:** GitHub cannot get a shell, read `.env`, or reach Postgres, Redis or
MinIO — all three are bound to `127.0.0.1` in the base compose file. A leaked key
cannot exfiltrate secrets. The common shape of this, a deploy key with a normal shell,
is meaningfully worse.

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

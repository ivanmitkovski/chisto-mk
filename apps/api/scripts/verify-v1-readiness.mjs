#!/usr/bin/env node
/**
 * Smoke-check v1 API endpoints after deploy + migrations.
 * Usage: API_BASE=https://your-alb.example node scripts/verify-v1-readiness.mjs
 * Optional: AUTH_TOKEN=eyJ... for authenticated routes.
 */
const base = (process.env.API_BASE ?? 'http://localhost:3000').replace(/\/$/, '');
const token = process.env.AUTH_TOKEN?.trim();

async function get(path, auth = false) {
  const headers = auth && token ? { Authorization: `Bearer ${token}` } : {};
  const res = await fetch(`${base}${path}`, { headers });
  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = text;
  }
  return { status: res.status, body };
}

async function main() {
  const checks = [];
  const health = await get('/health');
  checks.push({ name: 'GET /health', ok: health.status === 200 });

  const flags = await get('/v1/config/feature-flags');
  checks.push({ name: 'GET /v1/config/feature-flags', ok: flags.status === 200 });

  const metrics = await get('/metrics');
  checks.push({
    name: 'GET /metrics exposes prom-client',
    ok: metrics.status === 200 && String(metrics.body).includes('chisto_'),
  });

  if (token) {
    const blocks = await get('/v1/users/me/blocks', true);
    checks.push({
      name: 'GET /users/me/blocks (UGC moderation)',
      ok: blocks.status === 200 && Array.isArray(blocks.body),
    });
    const saved = await get('/v1/sites/saved?limit=5', true);
    const dsar = await get('/v1/auth/me/data-export', true);
    checks.push({
      name: 'GET /v1/auth/me/data-export',
      ok: dsar.status === 200,
    });
    checks.push({
      name: 'GET /sites/saved',
      ok: saved.status === 200 && Array.isArray(saved.body?.data),
    });
  } else {
    checks.push({
      name: 'GET /users/me/blocks (skipped — set AUTH_TOKEN)',
      ok: true,
    });
    checks.push({
      name: 'GET /sites/saved (skipped — set AUTH_TOKEN)',
      ok: true,
    });
  }

  let failed = 0;
  for (const c of checks) {
    const mark = c.ok ? 'OK' : 'FAIL';
    console.log(`${mark}  ${c.name}`);
    if (!c.ok) failed += 1;
  }
  if (failed > 0) {
    process.exit(1);
  }
  console.log('verify-v1-readiness: all checks passed');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

#!/usr/bin/env node
/**
 * Scoped supply-chain check: advisories on `apps__api>` dependency paths.
 * Critical findings are never waived. For high/moderate, optional `audit-waivers.json`
 * entries (until ISO date + ticket) suppress known transitive debt during burn-down.
 *
 * Usage (from monorepo root): node apps/api/scripts/audit-api-deps.mjs
 * Env: AUDIT_SEVERITY=critical|high|moderate (default critical)
 */
import { execSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..', '..', '..');
const severityOrder = { info: 0, low: 1, moderate: 2, high: 3, critical: 4 };
const minSeverity = (process.env.AUDIT_SEVERITY ?? 'critical').toLowerCase();
const minRank = severityOrder[minSeverity] ?? severityOrder.critical;

function loadWaivers() {
  const p = join(__dirname, 'audit-waivers.json');
  if (!existsSync(p)) {
    return new Map();
  }
  try {
    const j = JSON.parse(readFileSync(p, 'utf8'));
    const list = Array.isArray(j.waivers) ? j.waivers : [];
    const map = new Map();
    for (const w of list) {
      if (w && typeof w.id === 'number' && typeof w.until === 'string') {
        map.set(w.id, { until: w.until, ticket: w.ticket ?? '', note: w.note ?? '' });
      }
    }
    return map;
  } catch {
    return new Map();
  }
}

function waiverCovers(id, severity, waivers) {
  if (severity === 'critical') {
    return false;
  }
  const w = waivers.get(id);
  if (!w) {
    return false;
  }
  const end = Date.parse(`${w.until}T23:59:59.999Z`);
  if (!Number.isFinite(end) || Date.now() > end) {
    return false;
  }
  return true;
}

let raw;
try {
  raw = execSync('pnpm audit --json', { cwd: root, encoding: 'utf8', maxBuffer: 50 * 1024 * 1024 });
} catch (e) {
  const out = e.stdout ?? e.output?.[1];
  if (typeof out === 'string' && out.trim().startsWith('{')) {
    raw = out;
  } else {
    console.error('pnpm audit --json failed');
    process.exit(1);
  }
}

const data = JSON.parse(raw);
const advisories = data.advisories ?? {};
const waivers = loadWaivers();
const byId = new Map();

for (const action of data.actions ?? []) {
  for (const r of action.resolves ?? []) {
    if (typeof r.path !== 'string' || !r.path.startsWith('apps__api')) {
      continue;
    }
    const adv = advisories[String(r.id)];
    const sev = adv?.severity ?? 'low';
    const rank = severityOrder[sev] ?? 0;
    if (rank >= minRank) {
      const prev = byId.get(r.id);
      if (!prev || r.path.length < prev.path.length) {
        byId.set(r.id, {
          id: r.id,
          severity: sev,
          path: r.path,
          title: adv?.title,
        });
      }
    }
  }
}

const hits = [];
const waived = [];
for (const h of byId.values()) {
  if (waiverCovers(h.id, h.severity, waivers)) {
    waived.push(h);
  } else {
    hits.push(h);
  }
}

if (waived.length && process.env.AUDIT_VERBOSE === '1') {
  console.error(`API dependency audit: ${waived.length} waived (non-critical) advisory id(s).`);
}

if (hits.length) {
  console.error(`API dependency audit: ${hits.length} finding(s) at or above ${minSeverity}:\n`);
  for (const h of hits) {
    console.error(`- [${h.severity}] ${h.title}\n  ${h.path}\n`);
  }
  process.exit(1);
}

console.log(
  `OK: no ${minSeverity}+ advisories on apps__api dependency paths` +
    (waived.length ? ` (waivers applied: ${waived.length}).` : ' (no waivers).'),
);

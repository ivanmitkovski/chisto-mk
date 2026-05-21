#!/usr/bin/env node
/**
 * Fail CI when mutating routes lack @Idempotent or // safe-to-retry: on preceding lines.
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../src');
const EXEMPT_FILES = new Set([
  'auth/auth-session.controller.ts',
  'auth/auth-password.controller.ts',
  'auth/auth-mfa.controller.ts',
  'webhooks/webhooks.controller.ts',
  'webhooks/email-webhooks.controller.ts',
  'email/email-unsubscribe.controller.ts',
  'discovery-analytics/discovery-analytics.controller.ts',
]);

const MUTATE_RE = /@(Post|Put|Patch|Delete)\(/g;
const IDEMPOTENT = /@Idempotent\(/;
const SAFE_RETRY = /\/\/\s*safe-to-retry:/i;

function walk(dir, files = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p, files);
    else if (name.endsWith('.controller.ts')) files.push(p);
  }
  return files;
}

function coveredBefore(src, index) {
  const window = src.slice(Math.max(0, index - 500), index);
  return IDEMPOTENT.test(window) || SAFE_RETRY.test(window);
}

let failed = 0;
for (const file of walk(root)) {
  const rel = file.slice(root.length + 1);
  if (EXEMPT_FILES.has(rel)) continue;
  const src = readFileSync(file, 'utf8');
  MUTATE_RE.lastIndex = 0;
  let m;
  while ((m = MUTATE_RE.exec(src)) !== null) {
    if (coveredBefore(src, m.index)) continue;
    const line = src.slice(0, m.index).split('\n').length;
    console.error(`::error file=${rel},line=${line}::@${m[1]} missing @Idempotent or // safe-to-retry:`);
    failed += 1;
  }
}

if (failed > 0) {
  console.error(`${failed} mutating route(s) uncovered`);
  process.exit(1);
}
console.log('audit-mutating-routes: OK');

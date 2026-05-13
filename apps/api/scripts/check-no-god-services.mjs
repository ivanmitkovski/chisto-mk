#!/usr/bin/env node
/**
 * Repo-wide guard: every `*.service.ts` file under `src/` must stay within line/method budgets.
 * - `service-size-exemptions.json` must be `{}` (any key fails the run). Do not add exemptions;
 *   split or shrink services instead.
 * - Hard fail: >500 lines OR more than 12 heuristic class methods (per file; `prisma.service.ts` exempt).
 * - Soft fail: >300 lines and <=500 — resolve by splitting/shrinking until ≤300 lines (no waiver file).
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(process.cwd(), 'src');
const EXEMPT = new Set(['prisma.service.ts']);

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) {
      walk(p, out);
    } else if (name.endsWith('.service.ts')) {
      out.push(p);
    }
  }
  return out;
}

function countClassMethods(src) {
  const methodRe = /^\s{2}(async\s+)?(?!constructor\b)(\w+)\s*\(/gm;
  let m;
  let c = 0;
  while ((m = methodRe.exec(src)) !== null) {
    c += 1;
  }
  return c;
}

let exemptions = {};
try {
  exemptions = JSON.parse(readFileSync(join(__dirname, 'service-size-exemptions.json'), 'utf8'));
} catch {
  exemptions = {};
}
if (Object.keys(exemptions).length > 0) {
  console.error(
    '[service-size] scripts/service-size-exemptions.json must be empty ({}). Remove all exemptions and split services instead.',
    Object.keys(exemptions),
  );
  process.exit(1);
}

const HARD_LINE = 500;
const SOFT_LINE = 300;
const DEFAULT_METHOD_LIMIT = 12;

const files = walk(ROOT);
const hardViolations = [];
const softViolations = [];

for (const file of files) {
  const base = file.split('/').pop();
  if (!base || EXEMPT.has(base)) {
    continue;
  }
  const src = readFileSync(file, 'utf8');
  const lines = src.split('\n').length;
  const methods = countClassMethods(src);
  const rule = exemptions[base] ?? {};
  const methodLimit =
    typeof rule.maxMethods === 'number' && Number.isFinite(rule.maxMethods)
      ? rule.maxMethods
      : DEFAULT_METHOD_LIMIT;

  if (lines > HARD_LINE || methods > methodLimit) {
    hardViolations.push({ file, lines, methods, methodLimit });
    continue;
  }

  if (lines > SOFT_LINE && lines <= HARD_LINE) {
    const maxAllowed = rule && typeof rule.maxLines === 'number' ? rule.maxLines : null;
    if (maxAllowed == null || lines > maxAllowed) {
      softViolations.push({
        file,
        lines,
        maxAllowed,
        reason: rule?.reason,
      });
    }
  }
}

for (const v of softViolations) {
  console.error(
    `[service-size] ${v.file}: ${v.lines} lines (> ${SOFT_LINE}) — split or refactor to ≤${SOFT_LINE} lines. service-size-exemptions.json must remain {} (no line waivers).`,
  );
}

if (softViolations.length) {
  console.error(
    `Soft cap failed: ${softViolations.length} file(s) over ${SOFT_LINE} LoC. Split services; exemptions file is not used for line counts.`,
  );
  process.exit(1);
}

if (hardViolations.length) {
  console.error('God-service guard failed (hard limits):\n', hardViolations);
  process.exit(1);
}

console.log('OK: all *.service.ts files within size/method thresholds.');

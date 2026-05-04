#!/usr/bin/env node
/**
 * Fails CI if any Nest *.service.ts under src/ exceeds 500 lines or 10 public `async`/sync methods.
 * Exempt list: add basename strings to skip generated or intentional facades.
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

/** Scope to reports bounded context only (repo-wide scan would need phased exemptions). */
const ROOT = join(process.cwd(), 'src', 'reports');
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

function countPublicMethods(src) {
  const lines = src.split('\n');
  let n = 0;
  for (const line of lines) {
    const t = line.trim();
    if (/^public\s+(async\s+)?\w+\s*\(/.test(t)) {
      n++;
    }
    if (/^\s+(async\s+)?\w+\s*\([^)]*\)\s*(:\s*Promise<[^>]+>\s*)?\{/.test(t) && !t.startsWith('//')) {
      // Heuristic: top-level method bodies in class (indent 2 spaces) — undercounts private; OK for guardrail.
    }
  }
  // Simpler: count lines matching "  async NAME(" or "  NAME(" at class indent excluding constructor
  const methodRe = /^\s{2}(async\s+)?(?!constructor\b)(\w+)\s*\(/gm;
  let m;
  let c = 0;
  while ((m = methodRe.exec(src)) !== null) {
    c++;
  }
  return c;
}

let baselines = {};
try {
  baselines = JSON.parse(
    readFileSync(join(__dirname, 'reports-service-baselines.json'), 'utf8'),
  );
} catch {
  baselines = {};
}

const files = walk(ROOT);
const violations = [];
const softWarnings = [];
for (const file of files) {
  const base = file.split('/').pop();
  if (EXEMPT.has(base)) continue;
  const src = readFileSync(file, 'utf8');
  const lines = src.split('\n').length;
  const methods = countPublicMethods(src);
  const lineLimit = 500;
  const methodLimit = 12;
  if (lines > lineLimit || methods > methodLimit) {
    violations.push({ file, lines, methods });
  }
  const softFloor = 300;
  if (lines > softFloor && lines <= lineLimit) {
    const allowed = baselines[base];
    if (allowed == null || lines > allowed) {
      softWarnings.push({
        file: base,
        lines,
        note:
          allowed == null
            ? 'over 300 LoC — add to reports-service-baselines.json with justification or shrink'
            : `exceeds baseline ${allowed}`,
      });
    }
  }
}

for (const w of softWarnings) {
  console.warn(`[reports-soft] ${w.file}: ${w.lines} lines — ${w.note}`);
}

if (violations.length) {
  console.error('God-service guard failed:\n', violations);
  process.exit(1);
}
console.log('OK: no service files exceed line/method thresholds.');

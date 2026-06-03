#!/usr/bin/env node
/**
 * Guard: every `*.store.ts` file under `src/` must stay within line budget (≤300 lines).
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = join(process.cwd(), 'src');
const MAX_LINES = 300;

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) {
      walk(p, out);
    } else if (name.endsWith('.store.ts')) {
      out.push(p);
    }
  }
  return out;
}

const violations = [];
for (const file of walk(ROOT)) {
  const lines = readFileSync(file, 'utf8').split('\n').length;
  if (lines > MAX_LINES) {
    violations.push({ file, lines });
  }
}

if (violations.length) {
  console.error(`God-class guard failed: *.store.ts files must be ≤${MAX_LINES} lines:\n`, violations);
  process.exit(1);
}

console.log(`OK: all *.store.ts files within ${MAX_LINES} lines.`);

#!/usr/bin/env node
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = join(process.cwd(), 'src');
const SOFT_LINE = 300;
const MAX_ROUTES = 12;

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p, out);
    else if (name.endsWith('.controller.ts')) out.push(p);
  }
  return out;
}

function countRoutes(src) {
  const re = /@(Get|Post|Put|Patch|Delete|All)\(/g;
  let n = 0;
  while (re.exec(src)) n += 1;
  return n;
}

const violations = [];
for (const file of walk(ROOT)) {
  const src = readFileSync(file, 'utf8');
  const lines = src.split('\n').length;
  const routes = countRoutes(src);
  if (lines > SOFT_LINE || routes > MAX_ROUTES) {
    violations.push({ file, lines, routes });
  }
}

for (const v of violations) {
  console.error(
    `[controller-size] ${v.file}: ${v.lines} lines, ${v.routes} routes (max ${SOFT_LINE} lines / ${MAX_ROUTES} routes)`,
  );
}

if (violations.length) process.exit(1);
console.log('OK: all *.controller.ts files within size/route thresholds.');

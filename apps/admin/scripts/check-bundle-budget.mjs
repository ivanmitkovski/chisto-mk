#!/usr/bin/env node
/**
 * Compares post-build route chunk sizes against perf/route-budgets.json.
 * Run after `pnpm build` from apps/admin (or via pnpm test:bundle-budget).
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const adminRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const nextDir = path.join(adminRoot, '.next');
const manifestPath = path.join(nextDir, 'app-build-manifest.json');
const budgetsPath = path.join(adminRoot, 'perf', 'route-budgets.json');

const updateMode = process.argv.includes('--update');

function pageKeyForRoute(route) {
  if (route === '/dashboard') return '/dashboard/page';
  return `${route}/page`;
}

function sumChunkBytes(chunks) {
  let total = 0;
  const seen = new Set();
  for (const chunk of chunks) {
    if (!chunk.endsWith('.js')) continue;
    if (seen.has(chunk)) continue;
    seen.add(chunk);
    const filePath = path.join(nextDir, chunk);
    if (fs.existsSync(filePath)) {
      total += fs.statSync(filePath).size;
    }
  }
  return total;
}

function routeChunks(manifest, route) {
  const pageKey = pageKeyForRoute(route);
  const layoutKeys = ['/layout', '/dashboard/layout'];
  const chunks = [];
  for (const key of layoutKeys) {
    if (manifest.pages[key]) chunks.push(...manifest.pages[key]);
  }
  if (manifest.pages[pageKey]) chunks.push(...manifest.pages[pageKey]);
  return chunks;
}

if (!fs.existsSync(manifestPath)) {
  console.error('check-bundle-budget: missing .next/app-build-manifest.json — run `pnpm build` first.');
  process.exit(1);
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const budgets = JSON.parse(fs.readFileSync(budgetsPath, 'utf8'));
const regression = budgets.regressionPercent ?? 10;

const measured = {};
for (const route of Object.keys(budgets.routes)) {
  const bytes = sumChunkBytes(routeChunks(manifest, route));
  measured[route] = Math.ceil(bytes / 1024);
}

if (updateMode) {
  const next = { ...budgets, routes: measured };
  fs.writeFileSync(budgetsPath, `${JSON.stringify(next, null, 2)}\n`);
  console.log('check-bundle-budget: updated perf/route-budgets.json');
  for (const [route, kb] of Object.entries(measured)) {
    console.log(`  ${route}: ${kb} kB`);
  }
  process.exit(0);
}

let failed = false;
for (const [route, maxKb] of Object.entries(budgets.routes)) {
  const actualKb = measured[route];
  if (actualKb === undefined) {
    console.error(`check-bundle-budget: could not measure ${route} (missing page in manifest)`);
    failed = true;
    continue;
  }
  const allowedKb = Math.ceil(maxKb * (1 + regression / 100));
  const status = actualKb <= allowedKb ? 'OK' : 'FAIL';
  console.log(`${status} ${route}: ${actualKb} kB (budget ${maxKb} kB + ${regression}% → ${allowedKb} kB)`);
  if (actualKb > allowedKb) failed = true;
}

if (failed) {
  console.error('check-bundle-budget: one or more routes exceeded budget.');
  process.exit(1);
}

console.log('check-bundle-budget: OK');

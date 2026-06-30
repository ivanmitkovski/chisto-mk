#!/usr/bin/env node
/**
 * Compare k6 --summary-export JSON against perf/baseline-thresholds.json.
 * Usage: k6 run perf/k6-load-test.js --summary-export /tmp/summary.json && node scripts/check-k6-baseline.mjs /tmp/summary.json
 */
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const summaryPath = process.argv[2];
if (!summaryPath || !existsSync(summaryPath)) {
  console.error('Usage: node scripts/check-k6-baseline.mjs <path-to-k6-summary-export.json>');
  process.exit(1);
}

const thresholds = JSON.parse(readFileSync(join(__dirname, '..', 'perf', 'baseline-thresholds.json'), 'utf8'));
const summary = JSON.parse(readFileSync(summaryPath, 'utf8'));
const metrics = summary.metrics ?? {};

let failed = false;
for (const [name, cfg] of Object.entries(thresholds.metrics ?? {})) {
  const p95Max = cfg?.p95_max;
  if (typeof p95Max !== 'number') {
    continue;
  }
  const m = metrics[name];
  const p95 = m?.values?.['p(95)'];
  if (p95 == null) {
    console.warn(`[k6-baseline] skip: metric "${name}" missing from summary`);
    continue;
  }
  if (p95 > p95Max) {
    console.error(`[k6-baseline] FAIL ${name}: p(95)=${p95} > max ${p95Max}`);
    failed = true;
  } else {
    console.log(`[k6-baseline] OK ${name}: p(95)=${p95} <= ${p95Max}`);
  }
}

if (failed) {
  process.exit(1);
}
console.log('k6 baseline check passed.');

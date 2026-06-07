#!/usr/bin/env node
/**
 * Validates admin feature module structure and layering guardrails.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const adminSrc = path.join(root, 'apps/admin/src');
const featuresDir = path.join(adminSrc, 'features');

const DATA_BACKED_FEATURES = new Set([
  'broadcasts',
  'gamification',
  'app-config',
  'operations',
  'moderation',
  'audit',
  'auth',
  'dashboard-overview',
  'events',
  'map',
  'notifications',
  'reports',
  'settings',
  'sites',
  'users',
  'comms',
  'team',
]);

function walkFiles(dir, acc = []) {
  if (!fs.existsSync(dir)) return acc;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name === '.next') continue;
      walkFiles(full, acc);
    } else if (/\.(tsx?|jsx?)$/.test(entry.name) && !entry.name.endsWith('.test.ts')) {
      acc.push(full);
    }
  }
  return acc;
}

let failed = false;

function fail(message) {
  console.error(message);
  failed = true;
}

// 1. Every feature folder must have index.ts
const featureDirs = fs
  .readdirSync(featuresDir, { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name);

const missingIndex = featureDirs.filter((name) => {
  if (name === 'shared') return false;
  return !fs.existsSync(path.join(featuresDir, name, 'index.ts'));
});
if (missingIndex.length > 0) {
  fail(`Admin features missing index.ts: ${missingIndex.join(', ')}`);
}

// 2. Data-backed features must have data/ directory
const missingData = [...DATA_BACKED_FEATURES].filter((name) => {
  if (!fs.existsSync(path.join(featuresDir, name))) return false;
  return !fs.existsSync(path.join(featuresDir, name, 'data'));
});
if (missingData.length > 0) {
  fail(`Data-backed features missing data/ folder: ${missingData.join(', ')}`);
}

// 3. No features/ imports from app/
const featureFiles = walkFiles(featuresDir);
const appImportsInFeatures = featureFiles.filter((file) => {
  const content = fs.readFileSync(file, 'utf8');
  return /from ['"]@\/app\//.test(content) || /from ['"]\.\.\/.*app\//.test(content);
});
if (appImportsInFeatures.length > 0) {
  fail(
    `features/ must not import from app/:\n${appImportsInFeatures
      .map((f) => `  - ${path.relative(root, f)}`)
      .join('\n')}`,
  );
}

// 4. No lib/ imports from features/
const libDir = path.join(adminSrc, 'lib');
const libFiles = walkFiles(libDir);
const featureImportsInLib = libFiles.filter((file) => {
  const content = fs.readFileSync(file, 'utf8');
  return /from ['"]@\/features\//.test(content);
});
if (featureImportsInLib.length > 0) {
  fail(
    `lib/ must not import from features/:\n${featureImportsInLib
      .map((f) => `  - ${path.relative(root, f)}`)
      .join('\n')}`,
  );
}

// 5. No inline style={{ in admin src (except test files and skeleton layout helpers)
const adminFiles = walkFiles(adminSrc);
const SKELETON_LAYOUT_ALLOWLIST = /components\/ui\/skeleton\//;
const inlineStyleFiles = adminFiles.filter((file) => {
  const content = fs.readFileSync(file, 'utf8');
  if (!/style=\{\{/.test(content)) return false;
  return !SKELETON_LAYOUT_ALLOWLIST.test(path.relative(adminSrc, file));
});
if (inlineStyleFiles.length > 0) {
  fail(
    `Avoid inline style={{}} — use CSS modules:\n${inlineStyleFiles
      .map((f) => `  - ${path.relative(root, f)}`)
      .join('\n')}`,
  );
}

// 6. Dashboard routes with page.tsx must have loading.tsx using createDashboardLoadingPage
const dashboardAppDir = path.join(adminSrc, 'app', 'dashboard');
const dashboardPages = walkFiles(dashboardAppDir).filter(
  (f) => f.endsWith(`${path.sep}page.tsx`) && !f.includes(`${path.sep}api${path.sep}`),
);
const missingLoading = dashboardPages.filter((pageFile) => {
  const loadingFile = pageFile.replace(`${path.sep}page.tsx`, `${path.sep}loading.tsx`);
  return !fs.existsSync(loadingFile);
});
if (missingLoading.length > 0) {
  fail(
    `Dashboard routes missing loading.tsx:\n${missingLoading
      .map((f) => `  - ${path.relative(root, f)}`)
      .join('\n')}`,
  );
}

const loadingFiles = walkFiles(dashboardAppDir).filter((f) => f.endsWith(`${path.sep}loading.tsx`));
const loadingWithoutHelper = loadingFiles.filter((file) => {
  const content = fs.readFileSync(file, 'utf8');
  if (content.includes("'use client'")) return false;
  return !content.includes('createDashboardLoadingPage');
});
if (loadingWithoutHelper.length > 0) {
  fail(
    `Dashboard loading.tsx must use createDashboardLoadingPage (server routes):\n${loadingWithoutHelper
      .map((f) => `  - ${path.relative(root, f)}`)
      .join('\n')}`,
  );
}

// 7. Disallow ad-hoc @keyframes shimmer outside skeleton.module.css
const shimmerOutsideKit = adminFiles.filter((file) => {
  if (file.endsWith('skeleton.module.css')) return false;
  const content = fs.readFileSync(file, 'utf8');
  return /@keyframes\s+shimmer/.test(content);
});
if (shimmerOutsideKit.length > 0) {
  fail(
    `Use skeleton.module.css shimmer — remove @keyframes shimmer from:\n${shimmerOutsideKit
      .map((f) => `  - ${path.relative(root, f)}`)
      .join('\n')}`,
  );
}

if (failed) {
  process.exit(1);
}

console.log('check:admin-structure OK');

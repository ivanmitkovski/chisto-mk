#!/usr/bin/env node
/**
 * Guard: role-typed files (*.controller.ts, *.service.ts, *.gateway.ts, etc.)
 * must live in their role subfolder, not at module root.
 *
 * Set STRUCTURE_CHECK_ENFORCE=1 to fail the run (default: warn only).
 */
import { readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const SRC = join(process.cwd(), 'src');
const ENFORCE = process.env.STRUCTURE_CHECK_ENFORCE === '1';

/** Modules that stay flat (single-file role folders add no value). */
const FLAT_MODULES = new Set([
  'bootstrap',
  'config',
  'discovery-analytics',
  'health',
  'prisma',
  'public-config',
  'sessions',
  'users',
  'workers',
  'generated',
  'common',
]);

/** Subdirs that are preserved sub-domains — files inside are not checked. */
const PRESERVED_SUBDIRS = new Set([
  'dto',
  'feed',
  'map',
  'history',
  'http',
  'search',
  'repositories',
  'duplicates',
  'side-effects',
  'owner-events',
  'site-resolution',
  'ports',
  'pipes',
  'recorders',
  'senders',
  'guards',
  'interceptors',
  'templates',
  'assets',
  'quiz',
  'locales',
  'typesense',
  'offline',
  'candidates',
  'experiments',
  'explain',
  'features',
  'ranker',
  'rerank',
]);

const ROLE_RULES = [
  { pattern: /\.controller\.ts$/, folder: 'controllers' },
  { pattern: /\.repository\.ts$/, folder: 'repositories' },
  { pattern: /\.gateway\.ts$/, folder: 'gateways' },
  { pattern: /\.guard\.ts$/, folder: 'guards' },
  { pattern: /\.decorator\.ts$/, folder: 'decorators' },
  { pattern: /\.listener\.ts$/, folder: 'listeners' },
  { pattern: /\.strategy\.ts$/, folder: 'strategies' },
  { pattern: /-openapi\.decorators\.ts$/, folder: 'openapi' },
  { pattern: /\.service\.ts$/, folder: 'services' },
  { pattern: /\.constants\.ts$/, folder: 'constants' },
  { pattern: /\.types\.ts$/, folder: 'types' },
  { pattern: /\.type\.ts$/, folder: 'types' },
  { pattern: /\.util\.ts$/, folder: 'util' },
  { pattern: /\.helper(s)?\.ts$/, folder: 'util' },
  { pattern: /-events\.ts$/, folder: 'gateways' },
];

function roleForFile(name) {
  for (const rule of ROLE_RULES) {
    if (rule.pattern.test(name)) {
      return rule.folder;
    }
  }
  return null;
}

function walkModuleRoot(moduleDir, moduleName, violations) {
  if (FLAT_MODULES.has(moduleName)) {
    return;
  }
  let entries;
  try {
    entries = readdirSync(moduleDir);
  } catch {
    return;
  }
  for (const name of entries) {
    const full = join(moduleDir, name);
    if (!statSync(full).isFile() || !name.endsWith('.ts')) {
      continue;
    }
    if (name.endsWith('.module.ts')) {
      continue;
    }
    const role = roleForFile(name);
    if (role) {
      violations.push({
        file: relative(SRC, full),
        role,
        expected: `${moduleName}/${role}/${name}`,
      });
    }
  }
}

function walkSubdirs(moduleDir, moduleName, violations, depth = 0) {
  if (FLAT_MODULES.has(moduleName)) {
    return;
  }
  let entries;
  try {
    entries = readdirSync(moduleDir);
  } catch {
    return;
  }
  for (const name of entries) {
    const full = join(moduleDir, name);
    if (!statSync(full).isDirectory()) {
      continue;
    }
    if (PRESERVED_SUBDIRS.has(name)) {
      continue;
    }
    if (depth === 0 && name === 'dto') {
      continue;
    }
    walkSubdirs(full, moduleName, violations, depth + 1);
    for (const entry of readdirSync(full)) {
      const entryPath = join(full, entry);
      if (!statSync(entryPath).isFile() || !entry.endsWith('.ts')) {
        continue;
      }
      const role = roleForFile(entry);
      if (!role) {
        continue;
      }
      if (name !== role) {
        violations.push({
          file: relative(SRC, entryPath),
          role,
          expected: `${moduleName}/${role}/${entry}`,
        });
      }
    }
  }
}

const violations = [];
for (const name of readdirSync(SRC)) {
  const full = join(SRC, name);
  if (!statSync(full).isDirectory()) {
    continue;
  }
  walkModuleRoot(full, name, violations);
  walkSubdirs(full, name, violations);
}

if (violations.length === 0) {
  console.log('OK: module structure conforms to role-folder taxonomy.');
  process.exit(0);
}

for (const v of violations) {
  const msg = `[structure] ${v.file} should be in ${v.expected}`;
  if (ENFORCE) {
    console.error(msg);
  } else {
    console.warn(msg);
  }
}

if (ENFORCE) {
  console.error(`Structure check failed: ${violations.length} violation(s).`);
  process.exit(1);
}

console.warn(`Structure check: ${violations.length} warning(s) (warn-only mode).`);
process.exit(0);

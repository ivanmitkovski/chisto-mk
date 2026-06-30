#!/usr/bin/env node
/**
 * Ensures route-scoped i18n bundles include namespaces referenced by dashboard pages.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, '..');
const srcRoot = path.join(adminRoot, 'src');
const dashboardAppDir = path.join(srcRoot, 'app', 'dashboard');

const loadMessagesPath = path.join(srcRoot, 'i18n', 'load-messages.ts');
const loadMessagesSource = fs.readFileSync(loadMessagesPath, 'utf8');

function extractDashboardScopedNamespaces() {
  const block = loadMessagesSource.match(
    /export const DASHBOARD_SCOPED_NAMESPACES = \[([\s\S]*?)\] as const/,
  );
  if (!block) {
    throw new Error('Could not parse DASHBOARD_SCOPED_NAMESPACES from load-messages.ts');
  }
  return [...block[1].matchAll(/'([^']+)'/g)].map((match) => match[1]);
}

function extractRouteNamespaces() {
  const map = {};
  const block = loadMessagesSource.match(
    /const ROUTE_EXTRA_NAMESPACES[^=]*=\s*\{([\s\S]*?)\};/,
  );
  if (!block) {
    throw new Error('Could not parse ROUTE_EXTRA_NAMESPACES from load-messages.ts');
  }
  for (const match of block[1].matchAll(/'([^']+)':\s*\[([^\]]*)\]/g)) {
    const route = match[1];
    const namespaces = [...match[2].matchAll(/'([^']+)'/g)].map((m) => m[1]);
    map[route] = namespaces;
  }
  return map;
}

const CORE_NAMESPACES = ['common', 'nav', 'ui', 'auth', 'errors', 'commandPalette'];
const DASHBOARD_SCOPED_NAMESPACES = extractDashboardScopedNamespaces();

function namespacesForRoute(routePrefix, routeNamespaces) {
  if (routePrefix.startsWith('/dashboard')) {
    return new Set([...CORE_NAMESPACES, ...DASHBOARD_SCOPED_NAMESPACES]);
  }

  const extras = new Set();
  for (const [prefix, namespaces] of Object.entries(routeNamespaces)) {
    if (routePrefix === prefix || routePrefix.startsWith(`${prefix}/`)) {
      for (const ns of namespaces) extras.add(ns);
    }
  }
  return new Set([...CORE_NAMESPACES, ...extras]);
}

function walkPages(dir, acc = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkPages(full, acc);
    } else if (entry.name === 'page.tsx') {
      acc.push(full);
    }
  }
  return acc;
}

function extractNamespacesFromSource(source) {
  const namespaces = new Set();
  for (const match of source.matchAll(/getTranslations\(['"]([^'"]+)['"]\)/g)) {
    namespaces.add(match[1].split('.')[0]);
  }
  for (const match of source.matchAll(/getTranslations<['"]([^'"]+)['"]>/g)) {
    namespaces.add(match[1].split('.')[0]);
  }
  for (const match of source.matchAll(/useTranslations\(['"]([^'"]+)['"]\)/g)) {
    namespaces.add(match[1].split('.')[0]);
  }
  return namespaces;
}

function routePrefixFromPage(pageFile) {
  const rel = path.relative(dashboardAppDir, pageFile).replace(/\\/g, '/');
  const segments = rel.split('/').filter((s) => s !== 'page.tsx');
  if (segments.length === 0) return '/dashboard';
  return `/dashboard/${segments.join('/')}`;
}

const routeNamespaces = extractRouteNamespaces();
const issues = [];

for (const pageFile of walkPages(dashboardAppDir)) {
  const source = fs.readFileSync(pageFile, 'utf8');
  const used = extractNamespacesFromSource(source);
  if (used.size === 0) continue;

  const routePrefix = routePrefixFromPage(pageFile);
  const allowed = namespacesForRoute(routePrefix, routeNamespaces);
  const missing = [...used].filter((ns) => !allowed.has(ns));

  if (missing.length > 0) {
    issues.push({
      file: path.relative(srcRoot, pageFile),
      routePrefix,
      missing,
    });
  }
}

if (issues.length > 0) {
  console.error('check-admin-i18n-routes: namespace not in route bundle:');
  for (const issue of issues) {
    console.error(
      `  ${issue.file} (${issue.routePrefix}): missing ${issue.missing.join(', ')}`,
    );
  }
  process.exit(1);
}

console.log(`check-admin-i18n-routes: OK (${walkPages(dashboardAppDir).length} dashboard pages)`);

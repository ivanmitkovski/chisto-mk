#!/usr/bin/env node
/**
 * Detects likely next-intl double-prefix bugs: useTranslations('ns.segment')
 * combined with t('segment.key') in the same file.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const srcRoot = path.resolve(__dirname, '../src');

function walk(dir, files = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== 'node_modules' && entry.name !== '.next') {
        walk(full, files);
      }
      continue;
    }
    if (/\.(tsx?|jsx?)$/.test(entry.name)) {
      files.push(full);
    }
  }
  return files;
}

const issues = [];

for (const file of walk(srcRoot)) {
  const source = fs.readFileSync(file, 'utf8');
  const scopes = [
    ...source.matchAll(
      /(?:const|let)\s+(\w+)\s*=\s*useTranslations\(['"]([^'"]+\.[^'"]+)['"]\)/g,
    ),
  ];

  for (const [, varName, scope] of scopes) {
    const leaf = scope.split('.').pop();
    const patterns = [
      new RegExp(`\\b${varName}\\(['"\`]${leaf}\\.`),
      new RegExp(`\\b${varName}\\(\\\`\\$\\{?['"\`]?${leaf}\\.`),
    ];
    if (patterns.some((pattern) => pattern.test(source))) {
      issues.push({ file: path.relative(srcRoot, file), varName, scope, leaf });
    }
  }
}

if (issues.length > 0) {
  console.error('check-admin-i18n-scopes: possible double-prefix usage:');
  for (const issue of issues) {
    console.error(
      `  ${issue.file}: ${issue.varName} is scoped to "${issue.scope}" but also prefixes keys with "${issue.leaf}."`,
    );
  }
  process.exit(1);
}

console.log('check-admin-i18n-scopes: OK');

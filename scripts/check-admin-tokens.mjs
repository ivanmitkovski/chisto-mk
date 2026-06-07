#!/usr/bin/env node
/**
 * Ensures every var(--token) in admin src references a defined design token
 * or includes an explicit fallback: var(--token, fallback).
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const adminSrc = path.join(root, 'apps/admin/src');

/** @type {Set<string>} */
const definedTokens = new Set();

function collectDefinitionsFromCss(content) {
  for (const match of content.matchAll(/(--[a-zA-Z0-9_-]+)\s*:/g)) {
    definedTokens.add(match[1]);
  }
}

for (const file of [
  path.join(adminSrc, 'styles/tokens.css'),
  path.join(adminSrc, 'app/globals.css'),
]) {
  if (fs.existsSync(file)) {
    collectDefinitionsFromCss(fs.readFileSync(file, 'utf8'));
  }
}

function walkFiles(dir, acc = []) {
  if (!fs.existsSync(dir)) return acc;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name === '.next') continue;
      walkFiles(full, acc);
    } else if (/\.(tsx?|css|jsx?)$/.test(entry.name)) {
      acc.push(full);
    }
  }
  return acc;
}

for (const file of walkFiles(adminSrc)) {
  if (file.endsWith('.css')) {
    collectDefinitionsFromCss(fs.readFileSync(file, 'utf8'));
  }
}

/** @type {Array<{ file: string; token: string; line: number }>} */
const violations = [];

const varNoFallbackPattern = /var\(\s*(--[a-zA-Z0-9_-]+)\s*\)/g;

for (const file of walkFiles(adminSrc)) {
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  lines.forEach((line, index) => {
    for (const match of line.matchAll(varNoFallbackPattern)) {
      const token = match[1];
      if (!definedTokens.has(token)) {
        violations.push({
          file: path.relative(root, file),
          token,
          line: index + 1,
        });
      }
    }
  });
}

if (violations.length > 0) {
  console.error('Undefined CSS tokens (no fallback):\n');
  for (const v of violations) {
    console.error(`  ${v.file}:${v.line}  ${v.token}`);
  }
  process.exit(1);
}

console.log(`check:admin-tokens OK (${definedTokens.size} tokens defined)`);

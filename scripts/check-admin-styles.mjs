#!/usr/bin/env node
/**
 * Style guardrails for admin dashboard CSS:
 * - Overlay z-index must use var(--z-*)
 * - font-family must use var(--font-*)
 * - @media breakpoints must use the canonical rem scale
 * - Raw hex/rgba banned in components/ui CSS modules (tokens live in tokens.css)
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const adminSrc = path.join(root, 'apps/admin/src');

const CANON_BREAKPOINTS = new Set(['36rem', '48rem', '64rem', '90rem']);
const ALLOWED_BREAKPOINT_QUERIES = ['prefers-reduced-motion', 'prefers-color-scheme'];

/** Local stacking inside a component — numeric z-index allowed below this. */
const LOCAL_Z_INDEX_MAX = 10;

/** @type {Array<{ file: string; line: number; message: string }>} */
const violations = [];

function walkFiles(dir, acc = []) {
  if (!fs.existsSync(dir)) return acc;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name === '.next') continue;
      walkFiles(full, acc);
    } else if (/\.css$/.test(entry.name)) {
      acc.push(full);
    }
  }
  return acc;
}

/** @type {Array<{ file: string; line: number; message: string }>} */
const warnings = [];

function checkFile(file) {
  const rel = path.relative(root, file);
  const content = fs.readFileSync(file, 'utf8');
  const lines = content.split('\n');
  const isUiModule = rel.includes('apps/admin/src/components/ui/') && rel.endsWith('.module.css');
  const isFeatureModule =
    (rel.includes('apps/admin/src/features/') || rel.includes('apps/admin/src/app/')) &&
    rel.endsWith('.module.css');
  const enforceFeatureHex = process.env.ADMIN_STYLES_ENFORCE_FEATURE_HEX === '1';
  const isTokens = rel.endsWith('tokens.css') || rel.endsWith('globals.css');

  lines.forEach((line, index) => {
    const lineNo = index + 1;
    const trimmed = line.trim();

    if (trimmed.startsWith('/*') || trimmed.startsWith('*') || trimmed.startsWith('//')) {
      return;
    }

    const zMatch = trimmed.match(/z-index:\s*(.+?);/);
    if (zMatch) {
      const value = zMatch[1].trim();
      if (!value.startsWith('var(--z-')) {
        const numeric = Number.parseInt(value, 10);
        if (Number.isNaN(numeric) || numeric > LOCAL_Z_INDEX_MAX) {
          violations.push({
            file: rel,
            line: lineNo,
            message: `z-index must use var(--z-*) for overlay stacking (got "${value}")`,
          });
        }
      }
    }

    const fontMatch = trimmed.match(/font-family:\s*(.+?);/);
    if (fontMatch && !isTokens) {
      const value = fontMatch[1].trim();
      if (!value.startsWith('var(--font-') && value !== 'inherit') {
        violations.push({
          file: rel,
          line: lineNo,
          message: `font-family must use var(--font-*) or inherit (got "${value}")`,
        });
      }
    }

    const mediaMatch = trimmed.match(/@media\s*\(([^)]+)\)/);
    if (mediaMatch) {
      const query = mediaMatch[1].trim();
      const isAllowedFeature = ALLOWED_BREAKPOINT_QUERIES.some((feature) => query.includes(feature));
      if (!isAllowedFeature) {
        const widthMatch = query.match(/(?:min|max)-width:\s*([^)]+)/);
        if (widthMatch) {
          const bp = widthMatch[1].trim();
          if (!CANON_BREAKPOINTS.has(bp)) {
            violations.push({
              file: rel,
              line: lineNo,
              message: `@media breakpoint must be one of ${[...CANON_BREAKPOINTS].join(', ')} (got "${bp}")`,
            });
          }
        }
      }
    }

    if ((isUiModule || (isFeatureModule && enforceFeatureHex)) && !isTokens) {
      if (/#[0-9a-fA-F]{3,8}\b/.test(trimmed)) {
        violations.push({
          file: rel,
          line: lineNo,
          message: 'Raw hex colors are not allowed — use tokens.css',
        });
      }
    }

    if (isFeatureModule && !enforceFeatureHex && !isTokens) {
      if (/#[0-9a-fA-F]{3,8}\b/.test(trimmed)) {
        warnings.push({
          file: rel,
          line: lineNo,
          message: 'Raw hex in feature CSS — migrate to tokens.css (warn-only until ADMIN_STYLES_ENFORCE_FEATURE_HEX=1)',
        });
      }
    }
  });
}

for (const file of walkFiles(adminSrc)) {
  checkFile(file);
}

if (warnings.length > 0) {
  console.warn(`Admin style guardrail warnings (${warnings.length}):\n`);
  for (const w of warnings) {
    console.warn(`  ${w.file}:${w.line}  ${w.message}`);
  }
}

if (violations.length > 0) {
  console.error('Admin style guardrail violations:\n');
  for (const v of violations) {
    console.error(`  ${v.file}:${v.line}  ${v.message}`);
  }
  process.exit(1);
}

console.log('check:admin-styles OK');

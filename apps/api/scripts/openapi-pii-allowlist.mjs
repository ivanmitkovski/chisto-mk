#!/usr/bin/env node
/**
 * CI guard: public list/detail endpoints must not document raw PII fields.
 */
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const snapshot = JSON.parse(
  readFileSync(resolve(root, 'openapi/openapi.snapshot.json'), 'utf8'),
);

const banned = ['reporterId', 'phoneNumber', 'email', 'passwordHash'];
const pathPatterns = [
  '/sites/feed',
  '/sites/saved',
  '/sites/{id}/comments',
  '/events/{id}/participants',
  '/events/{id}/chat',
  '/rankings',
  '/sites/{id}',
  '/users/',
];

const paths = Object.keys(snapshot.paths ?? {});
let failed = 0;

for (const path of paths) {
  const matchesScope = pathPatterns.some((p) => path.includes(p.replace('{id}', '')) || path.includes(p));
  if (!matchesScope) continue;
  const raw = JSON.stringify(snapshot.paths[path]);
  for (const field of banned) {
    if (raw.includes(`"${field}"`)) {
      console.error(`::error::PII field "${field}" documented on ${path}`);
      failed += 1;
    }
  }
}

process.exit(failed > 0 ? 1 : 0);

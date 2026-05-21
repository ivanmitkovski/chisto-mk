#!/usr/bin/env node
/**
 * Regenerate OpenAPI snapshot + @chisto/api-client types; fail on dirty git diff.
 */
import { execSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function run(cmd, cwd = root) {
  console.log(`> ${cmd}`);
  execSync(cmd, { cwd, stdio: 'inherit', env: process.env });
}

run('pnpm --filter @chisto/api snapshot:openapi');
run('pnpm --filter @chisto/api-client generate');

const diff = execSync('git diff --name-only -- apps/api/openapi/openapi.snapshot.json packages/api-client/src/generated', {
  cwd: root,
  encoding: 'utf8',
}).trim();

if (diff) {
  console.error('Contract drift detected. Commit regenerated files:\n', diff);
  process.exit(1);
}
console.log('verify:contract OK');

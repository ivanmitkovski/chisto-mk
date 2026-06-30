#!/usr/bin/env node
import { execSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const pkgRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repoRoot = path.resolve(pkgRoot, '../..');
const input = path.join(repoRoot, 'apps/api/openapi/openapi.snapshot.json');
const output = path.join(pkgRoot, 'src/generated/schema.ts');

execSync(
  `pnpm exec openapi-typescript "${input}" -o "${output}"`,
  { cwd: pkgRoot, stdio: 'inherit' },
);

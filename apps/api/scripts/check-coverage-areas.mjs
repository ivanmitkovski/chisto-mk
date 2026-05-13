#!/usr/bin/env node
/**
 * Per-area coverage gates (Jest): runs focused test globs with collectCoverageFrom scoped to a src subtree.
 * Keeps global jest.config.js simple while enforcing minimums on security-sensitive areas.
 */
import { execSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const apiRoot = join(__dirname, '..');

const gates = [
  {
    name: 'auth',
    testPathPattern: 'test/auth',
    collectCoverageFrom: ['src/auth/**/*.ts', '!src/auth/**/*.module.ts'],
    threshold: { statements: 43, branches: 37, functions: 42, lines: 42 },
  },
  {
    name: 'event-chat',
    testPathPattern: 'test/event-chat',
    collectCoverageFrom: ['src/event-chat/**/*.ts', '!src/event-chat/**/*.module.ts'],
    threshold: { statements: 61, branches: 46, functions: 54, lines: 60 },
  },
  {
    name: 'events',
    testPathPattern: 'test/events',
    collectCoverageFrom: ['src/events/**/*.ts', '!src/events/**/*.module.ts'],
    threshold: { statements: 73, branches: 42, functions: 55, lines: 72 },
  },
  {
    name: 'sites',
    testPathPattern: 'test/sites',
    collectCoverageFrom: ['src/sites/**/*.ts', '!src/sites/**/*.module.ts'],
    threshold: { statements: 53, branches: 36, functions: 35, lines: 53 },
  },
  {
    name: 'cleanup-events',
    testPathPattern: 'test/cleanup-events',
    collectCoverageFrom: ['src/cleanup-events/**/*.ts', '!src/cleanup-events/**/*.module.ts'],
    threshold: { statements: 70, branches: 40, functions: 48, lines: 69 },
  },
  {
    name: 'reports',
    testPathPattern: 'test/reports',
    collectCoverageFrom: ['src/reports/**/*.ts', '!src/reports/**/*.module.ts'],
    threshold: { statements: 66, branches: 39, functions: 38, lines: 66 },
  },
  {
    name: 'gamification',
    testPathPattern: 'test/gamification',
    collectCoverageFrom: ['src/gamification/**/*.ts', '!src/gamification/**/*.module.ts'],
    threshold: { statements: 50, branches: 33, functions: 50, lines: 49 },
  },
  {
    name: 'admin-users',
    testPathPattern: 'test/admin-users',
    collectCoverageFrom: ['src/admin-users/**/*.ts', '!src/admin-users/**/*.module.ts'],
    threshold: { statements: 25, branches: 25, functions: 25, lines: 25 },
  },
  // Narrow prefix so this gate runs `test/admin/admin-*.spec.ts` only, not `test/admin-realtime`
  // (`admin-realtime` has a dedicated gate below).
  {
    name: 'admin',
    testPathPattern: 'test/admin/admin-',
    collectCoverageFrom: ['src/admin/**/*.ts', '!src/admin/**/*.module.ts'],
    threshold: { statements: 24, branches: 50, functions: 40, lines: 23 },
  },
  {
    name: 'admin-notifications',
    testPathPattern: 'test/admin-notifications',
    collectCoverageFrom: ['src/admin-notifications/**/*.ts', '!src/admin-notifications/**/*.module.ts'],
    threshold: { statements: 36, branches: 70, functions: 39, lines: 35 },
  },
  {
    name: 'admin-realtime',
    testPathPattern: 'test/admin-realtime',
    collectCoverageFrom: ['src/admin-realtime/**/*.ts', '!src/admin-realtime/**/*.module.ts'],
    threshold: { statements: 22, branches: 18, functions: 22, lines: 21 },
  },
];

function runGate(gate) {
  const cov = JSON.stringify({ global: gate.threshold });
  const collectArgs = gate.collectCoverageFrom.flatMap((p) => [`--collectCoverageFrom=${p}`]);
  const args = [
    'pnpm',
    'exec',
    'jest',
    '--config',
    'jest.config.areas.js',
    `--testPathPattern=${gate.testPathPattern}`,
    ...collectArgs,
    '--coverage',
    '--coverageReporters=text-summary',
    `--coverageThreshold=${cov}`,
    '--passWithNoTests',
    '--maxWorkers=50%',
  ];
  console.error(`\n[coverage-area] ${gate.name}: ${gate.testPathPattern}\n`);
  execSync(args.join(' '), { cwd: apiRoot, stdio: 'inherit', env: process.env });
}

for (const g of gates) {
  runGate(g);
}
console.error('\n[coverage-area] all gates passed\n');

#!/usr/bin/env node
/**
 * Pre-push guard: production Next.js builds delete `.next` and conflict with
 * running `next dev` servers (missing page.js.nft.json / corrupt output).
 */
import { execSync } from 'node:child_process';

const DEV_SERVERS = [
  { port: 3000, label: 'API (pnpm dev:api)' },
  { port: 3001, label: 'Admin (pnpm dev:admin)' },
  { port: 3002, label: 'Landing (pnpm dev:landing)' },
];

const listening = [];

for (const { port, label } of DEV_SERVERS) {
  try {
    execSync(`lsof -nP -iTCP:${port} -sTCP:LISTEN -t`, { stdio: ['ignore', 'pipe', 'ignore'] });
    listening.push({ port, label });
  } catch {
    // Port is free.
  }
}

if (listening.length === 0) {
  process.exit(0);
}

console.error('Local dev servers must be stopped before git push (pre-push runs pnpm ci:check / full build).');
for (const { port, label } of listening) {
  console.error(`  • ${label} — listening on :${port}`);
}
console.error('\nStop the dev processes above, then push again.');
process.exit(1);

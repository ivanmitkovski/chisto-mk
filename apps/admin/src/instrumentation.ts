/**
 * Prefer IPv4 when resolving hostnames. Some paths from cloud providers to AWS ALB fail on IPv6
 * while IPv4 works. Affects server-side fetch from Vercel → api.chisto.mk.
 * Use require() so webpack does not try to bundle `node:dns`.
 */
export function register() {
  if (process.env.NEXT_RUNTIME !== 'nodejs') return;
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const dns = require('dns') as typeof import('dns');
  dns.setDefaultResultOrder('ipv4first');
}

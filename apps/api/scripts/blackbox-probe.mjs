#!/usr/bin/env node
/**
 * Blackbox-style probe for /v1/health/ready — writes Prometheus textfile metric.
 */
const base = (process.env.API_BASE ?? 'http://127.0.0.1:3000').replace(/\/$/, '');
const out = process.env.PROBE_TEXTFILE ?? '/tmp/chisto_api_health_ready.prom';

async function main() {
  const url = `${base}/health/ready`;
  let ok = 0;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(5000) });
    ok = res.ok ? 1 : 0;
  } catch {
    ok = 0;
  }
  const body = `# HELP chisto_api_health_ready Blackbox probe of GET /health/ready\n# TYPE chisto_api_health_ready gauge\nchisto_api_health_ready ${ok}\n`;
  const fs = await import('node:fs/promises');
  await fs.writeFile(out, body);
  process.exit(ok ? 0 : 1);
}

main();

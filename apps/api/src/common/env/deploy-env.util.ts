export function isDeployedNodeEnv(nodeEnv = process.env.NODE_ENV ?? 'development'): boolean {
  const n = nodeEnv.trim().toLowerCase();
  return n === 'production' || n === 'staging';
}

export function requireRedisInDeployedEnv(feature: string): void {
  if (!isDeployedNodeEnv()) return;
  if (!process.env.REDIS_URL?.trim()) {
    throw new Error(`${feature} requires REDIS_URL in production/staging`);
  }
}

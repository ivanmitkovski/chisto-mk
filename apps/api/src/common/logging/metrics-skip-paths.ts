/** Paths excluded from access logs and HTTP metrics (probes). */
export const DEFAULT_METRICS_SKIP_PATHS = new Set<string>(['/health', '/metrics']);

export function normalizeHttpPath(urlOrPath: string): string {
  const withoutQuery = urlOrPath.split('?')[0] ?? '/';
  if (withoutQuery.length > 1 && withoutQuery.endsWith('/')) {
    return withoutQuery.slice(0, -1);
  }
  return withoutQuery || '/';
}

export function loadMetricsSkipPaths(): Set<string> {
  const raw = process.env.REQUEST_LOG_SKIP_PATHS?.trim();
  if (!raw) {
    return DEFAULT_METRICS_SKIP_PATHS;
  }
  const paths = new Set<string>();
  for (const part of raw.split(',')) {
    const p = part.trim();
    if (p) {
      paths.add(normalizeHttpPath(p));
    }
  }
  return paths;
}

export function shouldSkipMetricsForPath(
  url: string | undefined,
  logAllRequests: boolean,
  skipPaths: Set<string>,
): boolean {
  if (logAllRequests) {
    return false;
  }
  const path = normalizeHttpPath(url ?? '/');
  return skipPaths.has(path);
}

function connectionStringWithNoVerify(url: string): string {
  const noVerify = 'sslmode=no-verify';
  if (url.includes('sslmode=')) {
    return url.replace(/sslmode=[^&]*/i, noVerify);
  }
  const sep = url.includes('?') ? '&' : '?';
  return `${url}${sep}${noVerify}`;
}

function withConnectionTimeout(url: string, seconds = 30): string {
  if (url.includes('connect_timeout=')) {
    return url;
  }
  const sep = url.includes('?') ? '&' : '?';
  return `${url}${sep}connect_timeout=${seconds}`;
}

/** Same URL shaping as PrismaService (dev ssl relax + connect timeout). */
export function resolveDatabaseUrl(raw: string): string {
  const nodeEnv = process.env.NODE_ENV ?? 'development';
  let url = raw;
  if (nodeEnv !== 'production') {
    url = connectionStringWithNoVerify(url);
  }
  return withConnectionTimeout(url);
}

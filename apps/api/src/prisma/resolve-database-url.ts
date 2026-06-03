function connectionStringWithNoVerify(url: string): string {
  const noVerify = 'sslmode=no-verify';
  if (url.includes('sslmode=')) {
    return url.replace(/sslmode=[^&]*/i, noVerify);
  }
  const sep = url.includes('?') ? '&' : '?';
  return `${url}${sep}${noVerify}`;
}

function connectionStringWithSslDisabled(url: string): string {
  if (url.includes('sslmode=')) {
    return url.replace(/sslmode=[^&]*/i, 'sslmode=disable');
  }
  const sep = url.includes('?') ? '&' : '?';
  return `${url}${sep}sslmode=disable`;
}

function isLocalPostgresHost(url: string): boolean {
  try {
    const normalized = url.replace(/^postgresql:/i, 'http:').replace(/^postgres:/i, 'http:');
    const host = new URL(normalized).hostname.toLowerCase();
    return host === 'localhost' || host === '127.0.0.1' || host === 'postgres';
  } catch {
    return false;
  }
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
  if (isLocalPostgresHost(url)) {
    url = connectionStringWithSslDisabled(url);
  } else if (nodeEnv !== 'production') {
    url = connectionStringWithNoVerify(url);
  }
  return withConnectionTimeout(url);
}

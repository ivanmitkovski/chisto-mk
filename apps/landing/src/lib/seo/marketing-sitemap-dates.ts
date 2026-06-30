const LEGAL_PATHS = new Set(["/terms", "/privacy", "/cookies", "/data"]);

function parseEnvDate(value: string | undefined, fallback: Date): Date {
  if (!value?.trim()) return fallback;
  const ms = Date.parse(value.trim());
  return Number.isNaN(ms) ? fallback : new Date(ms);
}

/** Content-derived `lastModified` for static marketing paths in the sitemap. */
export function marketingPathLastModified(path: string, fallback: Date): Date {
  if (LEGAL_PATHS.has(path)) {
    return parseEnvDate(process.env.NEXT_PUBLIC_LEGAL_LAST_UPDATED_DATE, fallback);
  }
  if (path === "/contact" || path === "/press") {
    return parseEnvDate(process.env.NEXT_PUBLIC_LEGAL_EFFECTIVE_DATE, fallback);
  }
  if (path === "/about") {
    return parseEnvDate("2026-06-01", fallback);
  }
  if (path === "/news") {
    return parseEnvDate("2026-06-15", fallback);
  }
  if (path === "") {
    return fallback;
  }
  return fallback;
}

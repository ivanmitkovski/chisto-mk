export function chistoApiBase(): string {
  const raw = process.env.NEXT_PUBLIC_CHISTO_API_URL?.trim();
  const base = raw && raw.length > 0 ? raw : "https://api.chisto.mk/v1";
  return base.replace(/\/+$/, "");
}

export function chistoPublicSiteBase(): string {
  const raw = process.env.NEXT_PUBLIC_CHISTO_SITE_URL?.trim();
  const base = raw && raw.length > 0 ? raw : "https://chisto.mk";
  return base.replace(/\/+$/, "");
}

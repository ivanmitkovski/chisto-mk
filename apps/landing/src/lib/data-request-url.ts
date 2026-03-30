/** Resolves NEXT_PUBLIC_DATA_REQUEST_URL to an href (https or mailto). */
export function getDataRequestChannelHref(raw: string | undefined): string | null {
  const u = raw?.trim();
  if (!u) return null;
  if (/^https?:\/\//i.test(u)) return u;
  if (/^mailto:/i.test(u)) return u;
  if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(u)) return `mailto:${u}`;
  return null;
}

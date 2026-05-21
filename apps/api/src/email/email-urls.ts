import { DEFAULT_EMAIL_APP_BASE_URL } from './email.constants';
import { resolveEmailLogoSrc } from './email-logo';

/** Normalize HTTPS origin with no trailing slash. */
export function normalizeHttpsBase(raw: string | undefined): string {
  const s = raw?.trim() ?? '';
  if (!s) return '';
  try {
    const u = new URL(s.startsWith('http') ? s : `https://${s}`);
    return `${u.protocol}//${u.host}`;
  } catch {
    return '';
  }
}

/** EMAIL_APP_BASE_URL → SHARE_BASE_URL → https://chisto.mk */
export function resolveAppBaseUrl(cfg: {
  emailApp?: string | undefined;
  share?: string | undefined;
}): string {
  const fromEmail = normalizeHttpsBase(cfg.emailApp);
  if (fromEmail) return fromEmail;
  const fromShare = normalizeHttpsBase(cfg.share);
  if (fromShare) return fromShare;
  return DEFAULT_EMAIL_APP_BASE_URL;
}

/** Full HTTPS URL including path/query (for hosted images). Empty if invalid or non-HTTPS. */
export function normalizeHttpsAbsoluteUrl(raw: string | undefined): string {
  const s = raw?.trim() ?? '';
  if (!s) return '';
  try {
    const u = new URL(s.startsWith('http') ? s : `https://${s}`);
    if (u.protocol !== 'https:') return '';
    return u.toString();
  } catch {
    return '';
  }
}

/** @deprecated Use resolveEmailLogoSrc — kept for callers that import from email-urls. */
export function resolveLogoUrl(cfg: { logo?: string | undefined }): string {
  return resolveEmailLogoSrc(cfg);
}

import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { DEFAULT_EMAIL_LOGO_URL } from './email.constants';
import { normalizeHttpsAbsoluteUrl } from './email-urls';

const BRAND_LOGO_FILENAME = 'brand-logo.png';

let cachedEmbeddedDataUri: string | null | undefined;

function readLogoPngBytes(): Buffer | null {
  const candidates = [
    join(__dirname, 'assets', BRAND_LOGO_FILENAME),
    join(process.cwd(), 'dist', 'email', 'assets', BRAND_LOGO_FILENAME),
    join(process.cwd(), 'src', 'email', 'assets', BRAND_LOGO_FILENAME),
    join(process.cwd(), 'apps', 'api', 'src', 'email', 'assets', BRAND_LOGO_FILENAME),
  ];
  for (const p of candidates) {
    if (existsSync(p)) {
      return readFileSync(p);
    }
  }
  return null;
}

/** Inline PNG data URI — reliable in Gmail/Outlook (no redirect or hotlink). */
export function getEmbeddedEmailLogoDataUri(): string | null {
  if (cachedEmbeddedDataUri !== undefined) {
    return cachedEmbeddedDataUri;
  }
  const bytes = readLogoPngBytes();
  if (!bytes?.length) {
    cachedEmbeddedDataUri = null;
    return null;
  }
  cachedEmbeddedDataUri = `data:image/png;base64,${bytes.toString('base64')}`;
  return cachedEmbeddedDataUri;
}

/**
 * Hosted HTTPS logo when EMAIL_LOGO_URL is set; otherwise embedded PNG (fallback: www landing URL).
 */
export function resolveEmailLogoSrc(cfg: { logo?: string | undefined }): string {
  const configured = normalizeHttpsAbsoluteUrl(cfg.logo);
  if (configured) return configured;

  const embedded = getEmbeddedEmailLogoDataUri();
  if (embedded) return embedded;

  return DEFAULT_EMAIL_LOGO_URL;
}

/** @internal test helper */
export function resetEmbeddedEmailLogoCache(): void {
  cachedEmbeddedDataUri = undefined;
}

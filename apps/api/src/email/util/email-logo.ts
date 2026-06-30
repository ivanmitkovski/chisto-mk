import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { DEFAULT_EMAIL_LOGO_URL, EMAIL_LOGO_CONTENT_ID } from '../constants/email.constants';
import { normalizeHttpsAbsoluteUrl } from './email-url.util';

const BRAND_LOGO_FILENAME = 'brand-logo.png';

let cachedLogoBytes: Buffer | null | undefined;

export type EmailInlineAttachment = {
  contentId: string;
  name: string;
  contentType: string;
  contentBase64: string;
};

export type ResolvedEmailLogo = {
  logoUrl: string;
  inlineAttachment?: EmailInlineAttachment;
};

function readLogoPngBytes(): Buffer | null {
  if (cachedLogoBytes !== undefined) {
    return cachedLogoBytes;
  }
  const candidates = [
    join(__dirname, 'assets', BRAND_LOGO_FILENAME),
    join(process.cwd(), 'dist', 'email', 'assets', BRAND_LOGO_FILENAME),
    join(process.cwd(), 'src', 'email', 'assets', BRAND_LOGO_FILENAME),
    join(process.cwd(), 'apps', 'api', 'src', 'email', 'assets', BRAND_LOGO_FILENAME),
  ];
  for (const p of candidates) {
    if (existsSync(p)) {
      cachedLogoBytes = readFileSync(p);
      return cachedLogoBytes;
    }
  }
  cachedLogoBytes = null;
  return null;
}

function buildInlineLogoAttachment(bytes: Buffer): EmailInlineAttachment {
  return {
    contentId: EMAIL_LOGO_CONTENT_ID,
    name: BRAND_LOGO_FILENAME,
    contentType: 'image/png',
    contentBase64: bytes.toString('base64'),
  };
}

/**
 * Resolves logo src for HTML email.
 * Bundled PNG is sent as a CID inline attachment (Gmail/Outlook block data: URIs).
 */
export function resolveEmailLogo(cfg: { logo?: string | undefined }): ResolvedEmailLogo {
  const configured = normalizeHttpsAbsoluteUrl(cfg.logo);
  if (configured) {
    return { logoUrl: configured };
  }

  const bytes = readLogoPngBytes();
  if (bytes?.length) {
    return {
      logoUrl: `cid:${EMAIL_LOGO_CONTENT_ID}`,
      inlineAttachment: buildInlineLogoAttachment(bytes),
    };
  }

  return { logoUrl: DEFAULT_EMAIL_LOGO_URL };
}

/** Back-compat helper returning only the HTML img src. */
export function resolveEmailLogoSrc(cfg: { logo?: string | undefined }): string {
  return resolveEmailLogo(cfg).logoUrl;
}

/** Data URI for local HTML preview files (browser cannot resolve cid: without MIME). */
export function resolveEmailLogoPreviewSrc(cfg: { logo?: string | undefined }): string {
  const resolved = resolveEmailLogo(cfg);
  if (resolved.inlineAttachment) {
    return `data:image/png;base64,${resolved.inlineAttachment.contentBase64}`;
  }
  return resolved.logoUrl;
}

/** @internal test helper */
export function resetEmbeddedEmailLogoCache(): void {
  cachedLogoBytes = undefined;
}

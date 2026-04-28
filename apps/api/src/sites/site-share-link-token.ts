import { createHmac, randomUUID, timingSafeEqual } from 'node:crypto';
import { SiteShareChannel } from '../prisma-client';

const SITE_SHARE_LINK_PREFIX = 'chisto:site:v1:';

export const SITE_SHARE_LINK_TTL_SEC = 60 * 60 * 24 * 7;

export interface SiteShareLinkClaims {
  s: string;
  c: string;
  ch: SiteShareChannel;
  iat: number;
  exp: number;
}

export function newSiteShareCid(): string {
  return randomUUID();
}

export function signSiteShareLinkToken(secret: Buffer, claims: SiteShareLinkClaims): string {
  const body = Buffer.from(JSON.stringify(claims), 'utf8').toString('base64url');
  const sig = createHmac('sha256', secret).update(body).digest('base64url');
  return `${SITE_SHARE_LINK_PREFIX}${body}.${sig}`;
}

export type VerifySiteShareTokenFailureReason =
  | 'INVALID_FORMAT'
  | 'INVALID_SIGNATURE'
  | 'EXPIRED';

export function verifySiteShareLinkToken(
  secret: Buffer,
  raw: string,
  nowSec: number,
):
  | { ok: true; claims: SiteShareLinkClaims }
  | { ok: false; reason: VerifySiteShareTokenFailureReason } {
  if (!raw.startsWith(SITE_SHARE_LINK_PREFIX)) {
    return { ok: false, reason: 'INVALID_FORMAT' };
  }
  const rest = raw.slice(SITE_SHARE_LINK_PREFIX.length);
  const dot = rest.lastIndexOf('.');
  if (dot <= 0 || dot === rest.length - 1) {
    return { ok: false, reason: 'INVALID_FORMAT' };
  }
  const body = rest.slice(0, dot);
  const sig = rest.slice(dot + 1);
  const expectedSig = createHmac('sha256', secret).update(body).digest('base64url');
  const sigBuf = Buffer.from(sig, 'utf8');
  const expBuf = Buffer.from(expectedSig, 'utf8');
  if (sigBuf.length !== expBuf.length || !timingSafeEqual(sigBuf, expBuf)) {
    return { ok: false, reason: 'INVALID_SIGNATURE' };
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(Buffer.from(body, 'base64url').toString('utf8')) as unknown;
  } catch {
    return { ok: false, reason: 'INVALID_FORMAT' };
  }
  if (typeof parsed !== 'object' || parsed == null) {
    return { ok: false, reason: 'INVALID_FORMAT' };
  }
  const rec = parsed as Record<string, unknown>;
  if (
    typeof rec.s !== 'string' ||
    rec.s.length === 0 ||
    typeof rec.c !== 'string' ||
    rec.c.length === 0 ||
    typeof rec.ch !== 'string' ||
    !Object.values(SiteShareChannel).includes(rec.ch as SiteShareChannel) ||
    typeof rec.iat !== 'number' ||
    !Number.isFinite(rec.iat) ||
    typeof rec.exp !== 'number' ||
    !Number.isFinite(rec.exp)
  ) {
    return { ok: false, reason: 'INVALID_FORMAT' };
  }
  if (nowSec > rec.exp) {
    return { ok: false, reason: 'EXPIRED' };
  }
  return {
    ok: true,
    claims: {
      s: rec.s,
      c: rec.c,
      ch: rec.ch as SiteShareChannel,
      iat: rec.iat,
      exp: rec.exp,
    },
  };
}

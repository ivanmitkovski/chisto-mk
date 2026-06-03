import { createHmac, randomUUID, timingSafeEqual } from 'node:crypto';

export const CHECK_IN_QR_PREFIX = 'chisto:evt:v2:';

/** Server-side QR time-to-live (seconds). */
export const CHECK_IN_QR_TTL_SEC = 60;

export interface CheckInQrClaims {
  e: string;
  s: string;
  j: string;
  iat: number;
  exp: number;
}

export function signCheckInQrToken(
  secret: Buffer,
  claims: CheckInQrClaims,
): string {
  const body = Buffer.from(JSON.stringify(claims), 'utf8').toString('base64url');
  const sig = createHmac('sha256', secret).update(body).digest('base64url');
  return `${CHECK_IN_QR_PREFIX}${body}.${sig}`;
}

export type VerifyQrFailureReason =
  | 'INVALID_FORMAT'
  | 'INVALID_SIGNATURE'
  | 'EXPIRED';

export function verifyCheckInQrToken(
  secret: Buffer,
  raw: string,
  nowSec: number,
):
  | { ok: true; claims: CheckInQrClaims }
  | { ok: false; reason: VerifyQrFailureReason } {
  if (!raw.startsWith(CHECK_IN_QR_PREFIX)) {
    return { ok: false, reason: 'INVALID_FORMAT' };
  }
  const rest = raw.slice(CHECK_IN_QR_PREFIX.length);
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
    const json = Buffer.from(body, 'base64url').toString('utf8');
    parsed = JSON.parse(json) as unknown;
  } catch {
    return { ok: false, reason: 'INVALID_FORMAT' };
  }
  if (typeof parsed !== 'object' || parsed === null) {
    return { ok: false, reason: 'INVALID_FORMAT' };
  }
  const rec = parsed as Record<string, unknown>;
  const e = rec.e;
  const s = rec.s;
  const j = rec.j;
  const iat = rec.iat;
  const exp = rec.exp;
  if (
    typeof e !== 'string' ||
    e.length === 0 ||
    typeof s !== 'string' ||
    s.length === 0 ||
    typeof j !== 'string' ||
    j.length === 0 ||
    typeof iat !== 'number' ||
    !Number.isFinite(iat) ||
    typeof exp !== 'number' ||
    !Number.isFinite(exp)
  ) {
    return { ok: false, reason: 'INVALID_FORMAT' };
  }
  if (nowSec > exp) {
    return { ok: false, reason: 'EXPIRED' };
  }
  return { ok: true, claims: { e, s, j, iat, exp } };
}

export function newCheckInJti(): string {
  return randomUUID();
}

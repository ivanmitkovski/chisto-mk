import { randomInt, timingSafeEqual } from 'crypto';
import * as bcrypt from 'bcrypt';

const OTP_BCRYPT_ROUNDS = 12;

/** Six-digit numeric OTP for SMS flows. */
export function generateOtpCode(): string {
  return String(randomInt(100_000, 1_000_000));
}

export async function hashOtpCode(code: string): Promise<string> {
  return bcrypt.hash(code.trim(), OTP_BCRYPT_ROUNDS);
}

export async function verifyOtpCode(
  stored: { code?: string | null; codeHash?: string | null },
  provided: string,
): Promise<boolean> {
  const plain = String(provided ?? '').trim();
  if (plain.length === 0) {
    return false;
  }
  const hash = stored.codeHash?.trim();
  if (hash) {
    return bcrypt.compare(plain, hash);
  }
  return otpCodesMatch(String(stored.code ?? ''), plain);
}

export function otpCodesMatch(expected: string, provided: string): boolean {
  const a = String(expected ?? '').trim();
  const b = String(provided ?? '').trim();
  if (a.length !== b.length || a.length === 0) {
    return false;
  }
  return timingSafeEqual(Buffer.from(a), Buffer.from(b));
}

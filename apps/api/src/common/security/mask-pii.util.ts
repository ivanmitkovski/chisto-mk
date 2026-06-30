import { hashPiiForLog } from './pii-hash.util';

/** Mask email for logs: first char + *** + domain hash prefix. */
export function maskEmailForLog(email: string): string {
  const trimmed = email.trim().toLowerCase();
  const at = trimmed.indexOf('@');
  if (at <= 0) {
    return `hash:${hashPiiForLog(trimmed)}`;
  }
  const local = trimmed.slice(0, at);
  const domain = trimmed.slice(at + 1);
  const localMasked = local.length <= 1 ? '*' : `${local[0]}***`;
  return `${localMasked}@${domain.split('.')[0]?.slice(0, 2) ?? '**'}***`;
}

/** Mask phone for logs: keep last 2 digits only. */
export function maskPhoneForLog(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  if (digits.length <= 2) {
    return `hash:${hashPiiForLog(phone)}`;
  }
  return `***${digits.slice(-2)}`;
}

/** Truncate external API error bodies to avoid PII leakage. */
export function sanitizeExternalErrorDetail(detail: string, maxLen = 200): string {
  const trimmed = detail.trim();
  if (trimmed.length <= maxLen) {
    return trimmed;
  }
  return `${trimmed.slice(0, maxLen)}…`;
}

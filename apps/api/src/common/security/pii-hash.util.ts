import { createHash } from 'crypto';

export function hashPiiForLog(value: string): string {
  const normalized = value.trim().toLowerCase();
  if (normalized.length === 0) return 'empty';
  return createHash('sha256').update(normalized).digest('hex').slice(0, 12);
}

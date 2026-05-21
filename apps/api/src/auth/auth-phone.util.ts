/** Masks E.164 phone for client display, e.g. +38970123456 → +38970***456 */
export function maskPhoneNumber(phoneNumber: string): string {
  const normalized = phoneNumber.trim();
  if (normalized.length < 8) {
    return '***';
  }
  const visibleStart = Math.min(6, normalized.length - 4);
  const visibleEnd = 3;
  return (
    normalized.slice(0, visibleStart) +
    '*'.repeat(Math.max(3, normalized.length - visibleStart - visibleEnd)) +
    normalized.slice(-visibleEnd)
  );
}

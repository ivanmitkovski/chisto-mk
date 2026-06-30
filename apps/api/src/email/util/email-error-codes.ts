/** Non-retryable email delivery errors (purge terminal dead letters). */
export const EMAIL_TERMINAL_ERROR_PATTERNS = [
  'suppressed',
  'inactive',
  'hardbounce',
  'hard bounce',
  'spamcomplaint',
  'blocked',
  'invalid email',
  'not found',
] as const;

export function isEmailTerminalError(lastError: string | null | undefined): boolean {
  if (lastError == null || lastError.trim().length === 0) {
    return false;
  }
  const normalized = lastError.toLowerCase();
  return EMAIL_TERMINAL_ERROR_PATTERNS.some((pattern) => normalized.includes(pattern));
}

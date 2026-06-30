const WEAK_PATTERNS = [
  /^(.)\1{7,}$/,
  /^12345678$/,
  /^password$/i,
  /^password1$/i,
  /^qwerty123$/i,
  /^abc12345$/i,
  /^letmein\d*$/i,
  /^welcome\d*$/i,
  /^admin123$/i,
  /^changeme$/i,
];

export const E164_RE = /^\+[1-9]\d{7,14}$/;

type ValidationTranslator = (key: string) => string;

export function validateInvitePassword(password: string, t: ValidationTranslator): string | null {
  const value = password.trim();
  if (!value) return t('validation.passwordRequired');
  if (value.length < 8) return t('validation.passwordMinLength');
  if (value.length > 72) return t('validation.passwordMaxLength');
  if (!/\d/.test(value)) return t('validation.passwordNeedsNumber');
  if (!/[A-Za-z]/.test(value)) return t('validation.passwordNeedsLetter');

  const lower = value.toLowerCase();
  for (const pattern of WEAK_PATTERNS) {
    if (pattern.test(lower)) {
      return t('validation.passwordWeak');
    }
  }

  return null;
}

export function validateE164Phone(phone: string, t: ValidationTranslator): string | null {
  const trimmed = phone.trim();
  if (!trimmed) return t('validation.phoneRequired');
  if (!E164_RE.test(trimmed)) {
    return t('validation.phoneInvalid');
  }
  return null;
}

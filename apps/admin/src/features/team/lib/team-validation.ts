const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

type TeamValidationTranslate = (key: 'emailRequired' | 'emailInvalid') => string;

export function validateInviteEmail(email: string, t?: TeamValidationTranslate): string | null {
  const trimmed = email.trim();
  if (!trimmed) return t?.('emailRequired') ?? 'Email is required.';
  if (!EMAIL_RE.test(trimmed)) return t?.('emailInvalid') ?? 'Please enter a valid email address.';
  return null;
}

export function validateInviteName(name: string, t?: (key: 'firstNameRequired' | 'lastNameRequired') => string): string | null {
  const trimmed = name.trim();
  if (!trimmed) return t?.('firstNameRequired') ?? 'Name is required.';
  if (trimmed.length < 2) return t?.('firstNameRequired') ?? 'Name must be at least 2 characters.';
  return null;
}

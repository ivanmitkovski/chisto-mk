/** Minimal RFC-safe check so we only call the email provider for plausible mailbox addresses. */
const RECIPIENT_EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function isValidRecipientEmail(raw: string | null | undefined): boolean {
  const to = raw?.trim() ?? '';
  return to.length > 0 && to.length <= 320 && RECIPIENT_EMAIL.test(to);
}

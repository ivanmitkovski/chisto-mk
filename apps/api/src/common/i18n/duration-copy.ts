import type { AppLocale } from './app-locale';

/**
 * Canonical minute duration strings for user-facing copy (SMS, email, push, in-app).
 * Uses full words and native pluralization — no abbreviations unless SMS length forces it.
 */
export function formatDurationMinutes(locale: AppLocale, minutes: number): string {
  const m = Math.max(1, Math.round(minutes));

  switch (locale) {
    case 'mk':
      if (m % 10 === 1 && m % 100 !== 11) {
        return `${m} минута`;
      }
      return `${m} минути`;
    case 'sq':
      return m === 1 ? `${m} minute` : `${m} minuta`;
    default:
      return m === 1 ? `${m} minute` : `${m} minutes`;
  }
}

/** OTP / verification code validity line appended to SMS bodies. */
export function formatOtpCodeValidityPhrase(locale: AppLocale, minutes: number): string {
  const duration = formatDurationMinutes(locale, minutes);
  switch (locale) {
    case 'mk':
      return `Кодот важи ${duration}.`;
    case 'sq':
      return `Kodi skadon per ${duration}.`;
    default:
      return `The code is valid for ${duration}.`;
  }
}

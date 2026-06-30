import { ERROR_MESSAGES_EN } from './en.copy';
import { ERROR_MESSAGES_MK } from './mk.copy';
import { ERROR_MESSAGES_SQ } from './sq.copy';

export type ErrorMessageLocale = 'en' | 'mk' | 'sq';

const ERROR_MESSAGES: Record<ErrorMessageLocale, Record<string, string>> = {
  en: ERROR_MESSAGES_EN,
  mk: ERROR_MESSAGES_MK,
  sq: ERROR_MESSAGES_SQ,
};

/**
 * Maps `Accept-Language` to a supported error-message locale.
 * Returns `null` when the header is absent so callers keep the server default message.
 */
export function errorMessageLocaleFromAcceptLanguage(
  acceptLanguage?: string,
): ErrorMessageLocale | null {
  if (!acceptLanguage?.trim()) {
    return null;
  }
  const first = acceptLanguage.split(',')[0]?.trim().toLowerCase() ?? '';
  if (first.startsWith('sq')) {
    return 'sq';
  }
  if (first.startsWith('en')) {
    return 'en';
  }
  if (first.startsWith('mk')) {
    return 'mk';
  }
  return 'mk';
}

/**
 * Returns a localized API error message for `code` when `Accept-Language` is present.
 * Falls back to English copy, then `null` (keep the exception's original message).
 */
export function localizeErrorMessage(code: string, acceptLanguage?: string): string | null {
  const locale = errorMessageLocaleFromAcceptLanguage(acceptLanguage);
  if (!locale) {
    return null;
  }
  return ERROR_MESSAGES[locale][code] ?? ERROR_MESSAGES.en[code] ?? null;
}

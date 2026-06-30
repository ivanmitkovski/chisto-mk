export type ReportSubmitLocale = 'mk' | 'sq' | 'en';

/**
 * Parses `Accept-Language` to a supported report copy locale (defaults to `mk`).
 */
export function reportLocaleFromAcceptLanguage(header: string | string[] | undefined): ReportSubmitLocale {
  if (header === undefined) {
    return 'mk';
  }
  const raw = Array.isArray(header) ? header[0] : header;
  const first = raw.split(',')[0]?.trim().toLowerCase() ?? '';
  if (first.startsWith('sq')) {
    return 'sq';
  }
  if (first.startsWith('en')) {
    return 'en';
  }
  return 'mk';
}

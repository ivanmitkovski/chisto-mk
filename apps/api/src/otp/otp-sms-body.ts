import { localeFromAcceptLanguage } from '../common/utils/format-relative-time-since';
import { OtpSmsPurpose } from './otp-sender.interface';

/** Shown in SMS; keep ASCII in templates when possible for GSM-7 single-segment delivery. */
export const OTP_SMS_APP_LABEL = 'Chisto';

/** Supported bundles for OTP SMS (`mk` uses Cyrillic; `sq` stays Latin for GSM-7 where possible). */
export type OtpSmsLocale = 'en' | 'mk' | 'sq';

/**
 * Maps a client locale hint (e.g. Accept-Language) to a supported SMS bundle.
 */
export function otpSmsLocaleFromHint(localeHint?: string): OtpSmsLocale {
  const tag = localeFromAcceptLanguage(localeHint).toLowerCase().replace(/_/g, '-');
  if (tag.startsWith('mk')) {
    return 'mk';
  }
  if (tag.startsWith('sq')) {
    return 'sq';
  }
  return 'en';
}

export type BuildOtpSmsBodyInput = {
  code: string;
  purpose: OtpSmsPurpose;
  locale: OtpSmsLocale;
  expiryMinutes: number;
};

/**
 * Builds the outbound SMS body. Copy is intentionally short and avoids URLs.
 * Macedonian (`mk`) uses Cyrillic (UCS-2 segments may apply); Albanian (`sq`) uses Latin.
 */
export function buildOtpSmsBody(input: BuildOtpSmsBodyInput): string {
  const { code, purpose, locale, expiryMinutes } = input;
  const m = Math.max(1, Math.round(expiryMinutes));

  if (purpose === OtpSmsPurpose.PasswordReset) {
    switch (locale) {
      case 'mk':
        return `${OTP_SMS_APP_LABEL}: ${code} е кодот за ресетирање на лозинката. Важи ${m} мин.`;
      case 'sq':
        return `${OTP_SMS_APP_LABEL}: ${code} eshte kodi per rivendosjen e fjalekalimit. Skadon per ${m} min.`;
      default:
        return `${OTP_SMS_APP_LABEL}: ${code} is your password reset code. Expires in ${m} min.`;
    }
  }

  switch (locale) {
    case 'mk':
      return `${OTP_SMS_APP_LABEL}: ${code} е кодот за верификација на телефонот. Важи ${m} мин.`;
    case 'sq':
      return `${OTP_SMS_APP_LABEL}: ${code} eshte kodi per verifikimin e telefonit. Skadon per ${m} min.`;
    default:
      return `${OTP_SMS_APP_LABEL}: ${code} is your verification code. Expires in ${m} min.`;
  }
}

/// <reference types="jest" />
import { buildOtpSmsBody, otpSmsLocaleFromHint } from '../../src/otp/otp-sms-body';
import { OtpSmsPurpose } from '../../src/otp/otp-sender.interface';

describe('otpSmsLocaleFromHint', () => {
  it.each([
    [undefined, 'en'],
    ['', 'en'],
    ['en-US,en;q=0.9', 'en'],
    ['mk-MK,en;q=0.9', 'mk'],
    ['MK-mk', 'mk'],
    ['sq-AL', 'sq'],
    ['de-DE,en;q=0.8', 'en'],
  ])('maps %p to %s', (hint, expected) => {
    expect(otpSmsLocaleFromHint(hint)).toBe(expected);
  });
});

describe('buildOtpSmsBody', () => {
  const code = '4829';
  const expiryMinutes = 10;

  it('includes code and expiry for English phone verification', () => {
    const body = buildOtpSmsBody({
      code,
      purpose: OtpSmsPurpose.PhoneVerification,
      locale: 'en',
      expiryMinutes,
    });
    expect(body).toContain(code);
    expect(body).toContain('verification code');
    expect(body).toContain('10 min');
    expect(body).toContain('Chisto');
  });

  it('includes code and password reset wording in English', () => {
    const body = buildOtpSmsBody({
      code,
      purpose: OtpSmsPurpose.PasswordReset,
      locale: 'en',
      expiryMinutes,
    });
    expect(body).toContain(code);
    expect(body).toContain('password reset code');
    expect(body).not.toContain('verification code');
  });

  it('uses Macedonian Cyrillic bundle for phone verification', () => {
    const body = buildOtpSmsBody({
      code,
      purpose: OtpSmsPurpose.PhoneVerification,
      locale: 'mk',
      expiryMinutes,
    });
    expect(body).toContain(code);
    expect(body).toContain('верификација');
    expect(body).toContain('телефонот');
    expect(body).toContain('Важи 10 мин');
  });

  it('uses Macedonian Cyrillic bundle for password reset', () => {
    const body = buildOtpSmsBody({
      code,
      purpose: OtpSmsPurpose.PasswordReset,
      locale: 'mk',
      expiryMinutes,
    });
    expect(body).toContain(code);
    expect(body).toContain('ресетирање');
    expect(body).toContain('лозинката');
  });

  it('uses Albanian Latin bundle for password reset', () => {
    const body = buildOtpSmsBody({
      code,
      purpose: OtpSmsPurpose.PasswordReset,
      locale: 'sq',
      expiryMinutes,
    });
    expect(body).toContain(code);
    expect(body).toContain('fjalekalimit');
    expect(body).toContain('Skadon per 10 min');
  });

  it('does not include ignore-if-not-requested disclaimers in any locale', () => {
    const purposes = [OtpSmsPurpose.PhoneVerification, OtpSmsPurpose.PasswordReset] as const;
    const locales = ['en', 'mk', 'sq'] as const;
    for (const purpose of purposes) {
      for (const locale of locales) {
        const body = buildOtpSmsBody({ code: '9999', purpose, locale, expiryMinutes: 5 });
        expect(body).not.toMatch(/ignore this message|did not request|игнорирајте|побаравте|Nese nuk e kerkuat|injoroni/i);
      }
    }
  });

  it('rounds expiry to at least 1 minute', () => {
    const body = buildOtpSmsBody({
      code: '1111',
      purpose: OtpSmsPurpose.PhoneVerification,
      locale: 'en',
      expiryMinutes: 0.2,
    });
    expect(body).toContain('1 min');
  });
});

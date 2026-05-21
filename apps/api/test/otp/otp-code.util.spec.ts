import {
  generateOtpCode,
  hashOtpCode,
  otpCodesMatch,
  verifyOtpCode,
} from '../../src/otp/otp-code.util';

describe('otp-code.util', () => {
  it('generateOtpCode returns 6 digits', () => {
    const code = generateOtpCode();
    expect(code).toMatch(/^\d{6}$/);
  });

  it('otpCodesMatch is timing-safe for equal codes', () => {
    expect(otpCodesMatch('123456', '123456')).toBe(true);
    expect(otpCodesMatch('123456', '654321')).toBe(false);
  });

  it(
    'verifyOtpCode checks bcrypt hash and legacy plaintext',
    async () => {
      const code = '482910';
      const codeHash = await hashOtpCode(code);
      await expect(verifyOtpCode({ codeHash }, code)).resolves.toBe(true);
      await expect(verifyOtpCode({ codeHash }, '000000')).resolves.toBe(false);
      await expect(verifyOtpCode({ code }, code)).resolves.toBe(true);
    },
    20_000,
  );
});

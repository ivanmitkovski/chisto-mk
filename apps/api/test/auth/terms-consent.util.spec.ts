/// <reference types="jest" />

import {
  assertRegisterTermsAcceptance,
  requiresTermsAcceptance,
  termsConsentPayload,
  userHasCurrentTermsAcceptance,
} from '../../src/auth/terms-consent.util';

describe('terms-consent.util', () => {
  const current = '1';

  it('userHasCurrentTermsAcceptance is true when version and timestamp match', () => {
    expect(
      userHasCurrentTermsAcceptance(
        { termsAcceptedAt: new Date('2026-01-01'), termsVersion: '1' },
        current,
      ),
    ).toBe(true);
  });

  it('requiresTermsAcceptance when missing or outdated', () => {
    expect(requiresTermsAcceptance({ termsAcceptedAt: null, termsVersion: null }, current)).toBe(
      true,
    );
    expect(
      requiresTermsAcceptance(
        { termsAcceptedAt: new Date(), termsVersion: '0' },
        current,
      ),
    ).toBe(true);
  });

  it('termsConsentPayload exposes requiresTermsAcceptance', () => {
    const payload = termsConsentPayload(
      { termsAcceptedAt: new Date('2026-06-01'), termsVersion: '1' },
      current,
    );
    expect(payload.requiresTermsAcceptance).toBe(false);
    expect(payload.termsVersion).toBe('1');
  });

  it('assertRegisterTermsAcceptance rejects version mismatch', () => {
    expect(() =>
      assertRegisterTermsAcceptance(
        { termsAcceptedAt: new Date().toISOString(), termsVersion: '2' },
        current,
      ),
    ).toThrow();
  });
});

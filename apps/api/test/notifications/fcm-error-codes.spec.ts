import { remediationForFcmErrorCode } from '../../src/notifications/util/fcm-error-codes';

describe('fcm-error-codes', () => {
  it('maps third-party-auth-error to APNs remediation', () => {
    const hint = remediationForFcmErrorCode('messaging/third-party-auth-error');
    expect(hint).toContain('Development APNs auth key');
  });

  it('maps registration-token-not-registered to purge guidance', () => {
    const hint = remediationForFcmErrorCode('messaging/registration-token-not-registered');
    expect(hint).toContain('Purge undeliverable');
  });
});

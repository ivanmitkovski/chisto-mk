import { EmailSendEligibilityService } from '../../src/email/services/email-send-eligibility.service';

describe('EmailSendEligibilityService.canSendToAddress', () => {
  it('returns false when suppressed', async () => {
    const suppression = { isSuppressed: jest.fn().mockResolvedValue(true) };
    const service = new EmailSendEligibilityService(
      {} as never,
      { get: jest.fn() } as never,
      { ensureDefaults: jest.fn(), featureFlag: { findUnique: jest.fn() } } as never,
      suppression as never,
    );
    await expect(service.canSendToAddress('user@example.com')).resolves.toBe(false);
  });

  it('returns true for valid non-suppressed email', async () => {
    const suppression = { isSuppressed: jest.fn().mockResolvedValue(false) };
    const service = new EmailSendEligibilityService(
      {} as never,
      { get: jest.fn() } as never,
      { ensureDefaults: jest.fn(), featureFlag: { findUnique: jest.fn() } } as never,
      suppression as never,
    );
    await expect(service.canSendToAddress('user@example.com')).resolves.toBe(true);
  });
});

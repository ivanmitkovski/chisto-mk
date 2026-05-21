import { EmailSuppressionService } from '../../src/email/email-suppression.service';

describe('EmailSuppressionService', () => {
  const prisma = {
    emailSuppression: {
      deleteMany: jest.fn(),
      upsert: jest.fn(),
      findUnique: jest.fn(),
    },
  };

  let service: EmailSuppressionService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new EmailSuppressionService(prisma as never);
  });

  it('normalizes email to lowercase', () => {
    expect(service.normalizeEmail('  User@Example.COM ')).toBe('user@example.com');
  });

  it('records suppression via upsert', async () => {
    await service.record({
      email: 'User@Example.com',
      reason: 'HardBounce',
      payload: { recordType: 'HardBounce' },
    });

    expect(prisma.emailSuppression.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { email: 'user@example.com' },
        create: expect.objectContaining({
          email: 'user@example.com',
          reason: 'HardBounce',
        }),
      }),
    );
  });

  it('clears suppression when suppress is false', async () => {
    await service.record({
      email: 'user@example.com',
      reason: 'SubscriptionChange',
      suppress: false,
    });

    expect(prisma.emailSuppression.deleteMany).toHaveBeenCalledWith({
      where: { email: 'user@example.com' },
    });
    expect(prisma.emailSuppression.upsert).not.toHaveBeenCalled();
  });

  it('isSuppressed returns true when row exists', async () => {
    prisma.emailSuppression.findUnique.mockResolvedValue({ email: 'a@b.com' });
    await expect(service.isSuppressed('A@B.com')).resolves.toBe(true);
  });

  it('isSuppressed returns false when row missing', async () => {
    prisma.emailSuppression.findUnique.mockResolvedValue(null);
    await expect(service.isSuppressed('a@b.com')).resolves.toBe(false);
  });
});

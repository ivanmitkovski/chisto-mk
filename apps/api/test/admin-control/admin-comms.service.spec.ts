/// <reference types="jest" />

import { AdminCommsService } from '../../src/admin-control/services/admin-comms.service';

describe('AdminCommsService.createEmailSuppression', () => {
  it('upserts manual suppression with admin source and audits', async () => {
    const row = {
      email: 'user@example.com',
      reason: 'ManualSuppression',
      source: 'admin',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const prisma = {
      emailSuppression: {
        upsert: jest.fn().mockResolvedValue(row),
      },
    };
    const suppression = { normalizeEmail: jest.fn((email: string) => email.trim().toLowerCase()) };
    const audit = { log: jest.fn().mockResolvedValue(undefined) };
    const svc = new AdminCommsService(prisma as never, suppression as never, audit as never);

    const result = await svc.createEmailSuppression(' User@Example.com ', 'ManualSuppression', {
      userId: 'admin-1',
      email: 'admin@chisto.mk',
      phoneNumber: '+38970000001',
      role: 'ADMIN',
    });

    expect(suppression.normalizeEmail).toHaveBeenCalledWith(' User@Example.com ');
    expect(prisma.emailSuppression.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { email: 'user@example.com' },
        create: expect.objectContaining({ source: 'admin', reason: 'ManualSuppression' }),
      }),
    );
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'EMAIL_SUPPRESSION_CREATED',
        resourceId: 'user@example.com',
      }),
    );
    expect(result).toBe(row);
  });
});

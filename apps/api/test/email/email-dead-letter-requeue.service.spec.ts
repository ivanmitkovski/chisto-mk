/// <reference types="jest" />

import { EmailDeadLetterRequeueService } from '../../src/email/services/email-dead-letter-requeue.service';

describe('EmailDeadLetterRequeueService', () => {
  const prisma = {
    emailOutbox: {
      findMany: jest.fn(),
      updateMany: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
      findFirst: jest.fn(),
    },
  };

  const audit = { log: jest.fn().mockResolvedValue(undefined) };
  const service = new EmailDeadLetterRequeueService(prisma as never, audit as never);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('requeues actionable email dead letters', async () => {
    prisma.emailOutbox.findMany.mockResolvedValue([
      { id: 'dl-1', lastError: 'smtp timeout' },
      { id: 'dl-2', lastError: 'hard bounce for user@example.com' },
    ]);
    prisma.emailOutbox.updateMany.mockResolvedValue({ count: 1 });

    const result = await service.requeueAll();

    expect(result).toEqual({ requeued: 1 });
    expect(prisma.emailOutbox.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: { in: ['dl-1'] } },
      }),
    );
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'EMAIL_DLQ_REQUEUE' }),
    );
  });

  it('returns requeued false for terminal dead letter', async () => {
    prisma.emailOutbox.findFirst.mockResolvedValue({
      id: 'dl-terminal',
      lastError: 'hard bounce for user@example.com',
    });

    const result = await service.requeueOne('dl-terminal');

    expect(result).toEqual({ requeued: false });
    expect(prisma.emailOutbox.update).not.toHaveBeenCalled();
  });

  it('purges terminal email dead letters', async () => {
    prisma.emailOutbox.findMany.mockResolvedValue([
      { id: 'dl-terminal', lastError: 'hard bounce for user@example.com' },
      { id: 'dl-retry', lastError: 'smtp timeout' },
    ]);
    prisma.emailOutbox.deleteMany.mockResolvedValue({ count: 1 });

    const result = await service.purgeTerminal();

    expect(result).toEqual({ purged: 1 });
    expect(prisma.emailOutbox.deleteMany).toHaveBeenCalledWith({
      where: { id: { in: ['dl-terminal'] } },
    });
  });
});

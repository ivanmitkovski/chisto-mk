/// <reference types="jest" />

import { Prisma } from '../../src/prisma-client';
import { EcoEventPointsService } from '../../src/gamification/eco-event-points.service';

describe('EcoEventPointsService', () => {
  let service: EcoEventPointsService;

  beforeEach(() => {
    service = new EcoEventPointsService();
  });

  function makeTx() {
    const pointTransaction = {
      findFirst: jest.fn(),
      create: jest.fn(),
    };
    const user = {
      findUnique: jest.fn(),
      update: jest.fn(),
    };
    return { pointTransaction, user, tx: { pointTransaction, user } as never };
  }

  it('returns 0 when delta <= 0', async () => {
    const { tx, pointTransaction } = makeTx();
    const r = await service.creditIfNew(tx as never, {
      userId: 'u1',
      delta: 0,
      reasonCode: 'X',
      referenceType: 'T',
      referenceId: 'r1',
    });
    expect(r).toBe(0);
    expect(pointTransaction.findFirst).not.toHaveBeenCalled();
  });

  it('returns 0 when user missing', async () => {
    const { tx, pointTransaction, user } = makeTx();
    pointTransaction.findFirst.mockResolvedValue(null);
    user.findUnique.mockResolvedValue(null);
    const r = await service.creditIfNew(tx as never, {
      userId: 'missing',
      delta: 10,
      reasonCode: 'EVENT_JOINED',
      referenceType: 'EventParticipant',
      referenceId: 'p1',
    });
    expect(r).toBe(0);
    expect(pointTransaction.create).not.toHaveBeenCalled();
  });

  it('credits once and is idempotent on second call', async () => {
    const { tx, pointTransaction, user } = makeTx();
    pointTransaction.findFirst.mockResolvedValue(null);
    user.findUnique.mockResolvedValue({ pointsBalance: 100, totalPointsEarned: 200 });

    const params = {
      userId: 'u1',
      delta: 5,
      reasonCode: 'EVENT_JOINED',
      referenceType: 'EventParticipant',
      referenceId: 'p1',
    };

    const first = await service.creditIfNew(tx as never, params);
    expect(first).toBe(5);
    expect(pointTransaction.create).toHaveBeenCalledTimes(1);
    expect(user.update).toHaveBeenCalledWith({
      where: { id: 'u1' },
      data: { pointsBalance: 105, totalPointsEarned: 205 },
    });

    pointTransaction.findFirst.mockResolvedValue({ id: 'existing-tx' });
    const second = await service.creditIfNew(tx as never, params);
    expect(second).toBe(0);
    expect(pointTransaction.create).toHaveBeenCalledTimes(1);
  });

  it('treats P2002 on create as idempotent without updating balances', async () => {
    const { tx, pointTransaction, user } = makeTx();
    pointTransaction.findFirst.mockResolvedValue(null);
    user.findUnique.mockResolvedValue({ pointsBalance: 100, totalPointsEarned: 200 });
    const dup = new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
      code: 'P2002',
      clientVersion: 'test',
    });
    pointTransaction.create.mockRejectedValue(dup);
    const r = await service.creditIfNew(tx as never, {
      userId: 'u1',
      delta: 5,
      reasonCode: 'EVENT_JOINED',
      referenceType: 'EventParticipant',
      referenceId: 'p1',
    });
    expect(r).toBe(0);
    expect(user.update).not.toHaveBeenCalled();
  });

  describe('debitOnceIfNew', () => {
    it('returns 0 when delta >= 0', async () => {
      const { tx, pointTransaction } = makeTx();
      const r = await service.debitOnceIfNew(tx as never, {
        userId: 'u1',
        delta: 0,
        reasonCode: 'EVENT_JOIN_NO_SHOW',
        referenceType: 'CleanupEvent',
        referenceId: 'noShow:e1:u1',
      });
      expect(r).toBe(0);
      expect(pointTransaction.findFirst).not.toHaveBeenCalled();
    });

    it('returns 0 when user missing', async () => {
      const { tx, pointTransaction, user } = makeTx();
      pointTransaction.findFirst.mockResolvedValueOnce(null).mockResolvedValueOnce(null);
      user.findUnique.mockResolvedValue(null);
      const r = await service.debitOnceIfNew(tx as never, {
        userId: 'missing',
        delta: -5,
        reasonCode: 'EVENT_JOIN_NO_SHOW',
        referenceType: 'CleanupEvent',
        referenceId: 'noShow:e1:missing',
      });
      expect(r).toBe(0);
      expect(pointTransaction.create).not.toHaveBeenCalled();
    });

    it('debits once and is idempotent; skips without positive grant when onlyIfPositiveGrant set', async () => {
      const { tx, pointTransaction, user } = makeTx();
      pointTransaction.findFirst
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce({ id: 'grant' })
        .mockResolvedValueOnce({ id: 'existing-debit' });
      user.findUnique.mockResolvedValue({ pointsBalance: 100, totalPointsEarned: 200 });

      const params = {
        userId: 'u1',
        delta: -5 as const,
        reasonCode: 'EVENT_JOIN_NO_SHOW',
        referenceType: 'CleanupEvent',
        referenceId: 'noShow:e1:u1',
        onlyIfPositiveGrant: {
          reasonCode: 'EVENT_JOINED',
          referenceType: 'CleanupEvent',
          referenceId: 'e1',
        },
      };

      const first = await service.debitOnceIfNew(tx as never, params);
      expect(first).toBe(-5);
      expect(pointTransaction.create).toHaveBeenCalledTimes(1);
      expect(user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: { pointsBalance: 95, totalPointsEarned: 195 },
      });

      const second = await service.debitOnceIfNew(tx as never, params);
      expect(second).toBe(0);
      expect(pointTransaction.create).toHaveBeenCalledTimes(1);
    });

    it('returns 0 when onlyIfPositiveGrant has no matching positive txn', async () => {
      const { tx, pointTransaction, user } = makeTx();
      pointTransaction.findFirst.mockResolvedValueOnce(null).mockResolvedValueOnce(null);
      user.findUnique.mockResolvedValue({ pointsBalance: 100, totalPointsEarned: 200 });

      const r = await service.debitOnceIfNew(tx as never, {
        userId: 'u1',
        delta: -5,
        reasonCode: 'EVENT_JOIN_NO_SHOW',
        referenceType: 'CleanupEvent',
        referenceId: 'noShow:e1:u1',
        onlyIfPositiveGrant: {
          reasonCode: 'EVENT_JOINED',
          referenceType: 'CleanupEvent',
          referenceId: 'e1',
        },
      });

      expect(r).toBe(0);
      expect(pointTransaction.create).not.toHaveBeenCalled();
    });
  });
});

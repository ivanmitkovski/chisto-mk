/// <reference types="jest" />

import { GamificationService } from '../../src/gamification/services/gamification.service';
import { GamificationAwardSideEffectsService } from '../../src/gamification/services/gamification-award-side-effects.service';

describe('GamificationAwardSideEffectsService', () => {
  it('dispatches ACHIEVEMENT when level increases after credit', async () => {
    const gamification = new GamificationService();
    const dispatcher = { dispatchToUser: jest.fn().mockResolvedValue(undefined) };
    const prisma = {
      user: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      userDeviceToken: {
        findMany: jest.fn().mockResolvedValue([{ userId: 'u1', locale: 'en' }]),
      },
    };
    const service = new GamificationAwardSideEffectsService(
      prisma as never,
      gamification,
      dispatcher as never,
    );

    await service.notifyLevelUpAfterCredit('u1', {
      granted: 500,
      totalPointsEarnedBefore: 0,
      totalPointsEarnedAfter: 500,
    });

    expect(dispatcher.dispatchToUser).toHaveBeenCalledWith(
      'u1',
      expect.objectContaining({
        type: 'ACHIEVEMENT',
        data: expect.objectContaining({ kind: 'level_up' }),
        threadKey: expect.stringContaining(`achievement:level_up:u1:`),
      }),
    );
  });

  it('does not dispatch when level unchanged', async () => {
    const gamification = new GamificationService();
    const dispatcher = { dispatchToUser: jest.fn() };
    const service = new GamificationAwardSideEffectsService(
      { userDeviceToken: { findMany: jest.fn() } } as never,
      gamification,
      dispatcher as never,
    );

    await service.notifyLevelUpAfterCredit('u1', {
      granted: 5,
      totalPointsEarnedBefore: 10,
      totalPointsEarnedAfter: 15,
    });

    expect(dispatcher.dispatchToUser).not.toHaveBeenCalled();
  });
});

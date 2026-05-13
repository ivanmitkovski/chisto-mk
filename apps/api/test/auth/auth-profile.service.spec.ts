/// <reference types="jest" />

import { UnauthorizedException } from '@nestjs/common';
import { AuthProfileService } from '../../src/auth/auth-profile.service';
import { buildAuthenticatedUser } from '../factories';

describe('AuthProfileService', () => {
  it('me throws when user row is missing', async () => {
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue(null) },
    } as never;
    const uploads = { signPrivateObjectKey: jest.fn() } as never;
    const gamification = { getLevelProgress: jest.fn() } as never;
    const rankings = { getUserWeeklySummary: jest.fn() } as never;
    const svc = new AuthProfileService(prisma, uploads as never, gamification as never, rankings as never);
    const user = buildAuthenticatedUser({ userId: 'missing' });
    await expect(svc.me(user)).rejects.toBeInstanceOf(UnauthorizedException);
  });
});

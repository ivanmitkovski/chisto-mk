/// <reference types="jest" />

import { UnauthorizedException } from '@nestjs/common';
import { AuthProfileService } from '../../src/auth/auth-profile.service';
import { AuthProfileReadService } from '../../src/auth/auth-profile-read.service';
import { AuthProfileAvatarService } from '../../src/auth/auth-profile-avatar.service';
import { buildAuthenticatedUser } from '../factories';

describe('AuthProfileService', () => {
  it('me throws when user row is missing', async () => {
    const read = {
      me: jest.fn().mockRejectedValue(
        new UnauthorizedException({
          code: 'INVALID_TOKEN_USER',
          message: 'User for token was not found',
        }),
      ),
    } as unknown as AuthProfileReadService;
    const accountErasure = { eraseUserAccount: jest.fn() } as never;
    const configService = {
      get: jest.fn((key: string) => (key === 'TERMS_VERSION' ? '1' : undefined)),
    } as never;
    const audit = { log: jest.fn().mockResolvedValue(undefined) } as never;
    const svc = new AuthProfileService(
      { user: { findUnique: jest.fn() } } as never,
      { signPrivateObjectKey: jest.fn() } as never,
      read,
      {} as AuthProfileAvatarService,
      accountErasure,
      configService,
      audit,
    );
    const user = buildAuthenticatedUser({ userId: 'missing' });
    await expect(svc.me(user)).rejects.toBeInstanceOf(UnauthorizedException);
    expect(read.me).toHaveBeenCalledWith(user, 'en');
  });
});

/// <reference types="jest" />
import { ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '../../src/prisma-client';
import { RolesGuard } from '../../src/auth/roles.guard';
import { ROLES_KEY } from '../../src/auth/roles.decorator';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';

describe('RolesGuard', () => {
  const audit = { log: jest.fn().mockResolvedValue(undefined) };

  function ctxWithUser(user?: AuthenticatedUser) {
    return {
      switchToHttp: () => ({
        getRequest: () => ({ user, method: 'GET', path: '/test' }),
      }),
      getHandler: () => jest.fn(),
      getClass: () => jest.fn(),
    };
  }

  it('denies when @Roles metadata is missing (fail closed)', () => {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue(undefined) };
    const guard = new RolesGuard(reflector as unknown as Reflector, audit as never);
    expect(() => guard.canActivate(ctxWithUser() as never)).toThrow(ForbiddenException);
  });

  it('denies when @Roles is empty array', () => {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue([]) };
    const guard = new RolesGuard(reflector as unknown as Reflector, audit as never);
    expect(() => guard.canActivate(ctxWithUser() as never)).toThrow(ForbiddenException);
  });

  it('allows when user role is listed in @Roles', () => {
    const reflector = {
      getAllAndOverride: jest.fn().mockImplementation((key: string) => {
        if (key === ROLES_KEY) return [Role.ADMIN];
        return undefined;
      }),
    };
    const guard = new RolesGuard(reflector as unknown as Reflector, audit as never);
    const user: AuthenticatedUser = {
      userId: 'u1',
      email: 'a@b.c',
      phoneNumber: '+1',
      role: Role.ADMIN,
    };
    expect(guard.canActivate(ctxWithUser(user) as never)).toBe(true);
  });
});

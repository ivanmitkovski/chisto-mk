/// <reference types="jest" />
import { ForbiddenException } from '@nestjs/common';
import { Role } from '../../src/prisma-client';
import { assertReportVisibleToUser } from '../../src/common/helpers/assert-ownership.helper';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';

describe('assertReportVisibleToUser', () => {
  const modRoles = [Role.SUPPORT, Role.ADMIN] as const;
  const user = (role: Role, id = 'u-me'): AuthenticatedUser => ({
    userId: id,
    email: 'x@y.z',
    phoneNumber: '+1',
    role,
  });

  it('throws when citizen is neither reporter nor co-reporter', () => {
    expect(() =>
      assertReportVisibleToUser(
        { id: 'r1', reporterId: 'u-other' },
        [],
        user(Role.USER),
        modRoles,
      ),
    ).toThrow(ForbiddenException);
  });

  it('allows reporter', () => {
    expect(() =>
      assertReportVisibleToUser(
        { id: 'r1', reporterId: 'u-me' },
        [],
        user(Role.USER),
        modRoles,
      ),
    ).not.toThrow();
  });

  it('allows co-reporter', () => {
    expect(() =>
      assertReportVisibleToUser(
        { id: 'r1', reporterId: 'u-other' },
        ['u-me'],
        user(Role.USER),
        modRoles,
      ),
    ).not.toThrow();
  });

  it('allows moderator without ownership', () => {
    expect(() =>
      assertReportVisibleToUser(
        { id: 'r1', reporterId: 'u-other' },
        [],
        user(Role.ADMIN),
        modRoles,
      ),
    ).not.toThrow();
  });
});

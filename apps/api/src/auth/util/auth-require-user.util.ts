import { UnauthorizedException } from '@nestjs/common';
import type { AuthenticatedUser } from '../types/authenticated-user.type';

export function requireAuthenticatedUser(
  user: AuthenticatedUser | undefined,
): AuthenticatedUser {
  if (!user) {
    throw new UnauthorizedException({
      code: 'UNAUTHORIZED',
      message: 'Authentication required',
    });
  }
  return user;
}

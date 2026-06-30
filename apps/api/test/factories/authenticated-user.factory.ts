import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { Role } from '../../src/prisma-client';

export function buildAuthenticatedUser(
  overrides: Partial<Omit<AuthenticatedUser, 'role'>> & { role?: Role } = {},
): AuthenticatedUser {
  const id = overrides.userId ?? 'user_test_1';
  return {
    userId: id,
    email: overrides.email ?? `${id}@test.chisto.mk`,
    phoneNumber: overrides.phoneNumber ?? '+38970000001',
    role: overrides.role ?? Role.USER,
  };
}

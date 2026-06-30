import { Role, UserStatus } from '../../src/prisma-client';

type UserRow = {
  id: string;
  createdAt: Date;
  updatedAt: Date;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  passwordHash: string;
  role: Role;
  status: UserStatus;
  isPhoneVerified: boolean;
  pointsBalance: number;
  totalPointsEarned: number;
  totalPointsSpent: number;
  lastActiveAt: Date | null;
  avatarObjectKey: string | null;
  avatarUpdatedAt: Date | null;
  organizerCertifiedAt: Date | null;
};

export function buildUserRow(overrides: Partial<UserRow> = {}): UserRow {
  const id = overrides.id ?? 'user_row_1';
  const now = overrides.createdAt ?? new Date('2026-01-01T00:00:00.000Z');
  return {
    id,
    createdAt: overrides.createdAt ?? now,
    updatedAt: overrides.updatedAt ?? now,
    firstName: overrides.firstName ?? 'Test',
    lastName: overrides.lastName ?? 'User',
    email: overrides.email ?? `${id}@test.chisto.mk`,
    phoneNumber: overrides.phoneNumber ?? '+38970000001',
    passwordHash: overrides.passwordHash ?? '$2b$04$placeholderhashplaceholderhashplac',
    role: overrides.role ?? Role.USER,
    status: overrides.status ?? UserStatus.ACTIVE,
    isPhoneVerified: overrides.isPhoneVerified ?? true,
    pointsBalance: overrides.pointsBalance ?? 0,
    totalPointsEarned: overrides.totalPointsEarned ?? 0,
    totalPointsSpent: overrides.totalPointsSpent ?? 0,
    lastActiveAt: overrides.lastActiveAt ?? null,
    avatarObjectKey: overrides.avatarObjectKey ?? null,
    avatarUpdatedAt: overrides.avatarUpdatedAt ?? null,
    organizerCertifiedAt: overrides.organizerCertifiedAt ?? null,
  };
}

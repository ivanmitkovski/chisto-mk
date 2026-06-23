import { describe, expect, it } from 'vitest';
import { USERS_QUICK_STATUS_FILTERS, USERS_ROLE_OPTIONS, USERS_STATUS_OPTIONS } from './users-list-filters';

const VALID_ROLES = new Set(['USER', 'SUPPORT', 'ADMIN', 'SUPER_ADMIN']);
const VALID_STATUSES = new Set(['ACTIVE', 'SUSPENDED', 'DELETED']);

describe('users-list-filters', () => {
  it('role options match Prisma Role enum', () => {
    const values = USERS_ROLE_OPTIONS.map((o) => o.value).filter(Boolean);
    for (const value of values) {
      expect(VALID_ROLES.has(value)).toBe(true);
    }
    expect(values).toContain('SUPPORT');
    expect(values).not.toContain('MODERATOR');
  });

  it('status options match Prisma UserStatus enum', () => {
    const values = USERS_STATUS_OPTIONS.map((o) => o.value).filter(Boolean);
    for (const value of values) {
      expect(VALID_STATUSES.has(value)).toBe(true);
    }
    expect(values).toContain('DELETED');
  });

  it('quick status filters are a subset of status options', () => {
    const statusValues = new Set(USERS_STATUS_OPTIONS.map((o) => o.value));
    for (const chip of USERS_QUICK_STATUS_FILTERS) {
      expect(statusValues.has(chip.value)).toBe(true);
    }
  });
});

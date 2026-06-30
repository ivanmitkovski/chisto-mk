import { describe, expect, it } from 'vitest';
import { can as hasPermission } from '@/lib/auth/rbac/permissions';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';

describe('require-permission helpers', () => {
  it('grants team:read only to super admin', () => {
    expect(hasPermission('SUPER_ADMIN', ADMIN_PERMISSIONS['team:read'])).toBe(true);
    expect(hasPermission('ADMIN', ADMIN_PERMISSIONS['team:read'])).toBe(false);
    expect(hasPermission('SUPPORT', ADMIN_PERMISSIONS['team:read'])).toBe(false);
  });

  it('grants reports:moderate to support and above', () => {
    expect(hasPermission('SUPPORT', ADMIN_PERMISSIONS['reports:moderate'])).toBe(true);
    expect(hasPermission('ADMIN', ADMIN_PERMISSIONS['reports:moderate'])).toBe(true);
  });

  it('denies unknown roles', () => {
    expect(hasPermission('USER', ADMIN_PERMISSIONS['dashboard:view'])).toBe(false);
    expect(hasPermission(null, ADMIN_PERMISSIONS['dashboard:view'])).toBe(false);
  });
});

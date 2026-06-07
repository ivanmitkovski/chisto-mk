import { describe, expect, it } from 'vitest';
import { permissionsForRole, can } from './permissions';

describe('permissions', () => {
  it('grants reports:merge only to ADMIN and above', () => {
    expect(can('SUPPORT', 'reports:merge')).toBe(false);
    expect(can('ADMIN', 'reports:merge')).toBe(true);
    expect(can('SUPER_ADMIN', 'reports:merge')).toBe(true);
  });

  it('grants moderation:write only to ADMIN and above', () => {
    expect(can('SUPPORT', 'moderation:write')).toBe(false);
    expect(can('ADMIN', 'moderation:write')).toBe(true);
  });

  it('returns SUPPORT permissions list', () => {
    const perms = permissionsForRole('SUPPORT');
    expect(perms).toContain('reports:read');
    expect(perms).not.toContain('reports:merge');
  });
});

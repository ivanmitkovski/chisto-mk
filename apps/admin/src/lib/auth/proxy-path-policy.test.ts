import { describe, expect, it } from 'vitest';
import { isProxyPathAllowed, normalizeProxyPathSegments } from './proxy-path-policy';

describe('proxy-path-policy', () => {
  it('allows known admin prefixes', () => {
    expect(isProxyPathAllowed('/admin/users')).toBe(true);
    expect(isProxyPathAllowed('/auth/me')).toBe(true);
    expect(isProxyPathAllowed('/sites/admin/list')).toBe(true);
  });

  it('allows schedule conflict preview for event forms', () => {
    expect(isProxyPathAllowed('/events/check-conflict')).toBe(true);
  });

  it('rejects other citizen events routes', () => {
    expect(isProxyPathAllowed('/events')).toBe(false);
    expect(isProxyPathAllowed('/events/search')).toBe(false);
  });

  it('rejects path traversal segments', () => {
    expect(normalizeProxyPathSegments(['..', 'admin', 'users'])).toBeNull();
    expect(isProxyPathAllowed('/../admin/users')).toBe(false);
  });
});

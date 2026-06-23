import { describe, expect, it } from 'vitest';
import { buildActiveUsersListQuery } from '../data/active-users-adapter.client';

describe('buildActiveUsersListQuery', () => {
  it('serializes page, limit, and optional filters', () => {
    const query = buildActiveUsersListQuery({
      page: 2,
      limit: 25,
      status: 'online',
      platform: 'IOS',
      search: ' ada ',
    });
    const params = new URLSearchParams(query);
    expect(params.get('page')).toBe('2');
    expect(params.get('limit')).toBe('25');
    expect(params.get('status')).toBe('online');
    expect(params.get('platform')).toBe('IOS');
    expect(params.get('search')).toBe('ada');
  });

  it('omits empty filters', () => {
    const query = buildActiveUsersListQuery({ page: 1 });
    const params = new URLSearchParams(query);
    expect(params.get('page')).toBe('1');
    expect(params.get('status')).toBeNull();
    expect(params.get('platform')).toBeNull();
    expect(params.get('search')).toBeNull();
  });
});

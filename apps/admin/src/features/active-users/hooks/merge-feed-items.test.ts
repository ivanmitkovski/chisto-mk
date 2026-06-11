import { describe, expect, it } from 'vitest';
import { mergeFeedItems } from '@/features/active-users/hooks/merge-feed-items';
import type { ActivityFeedItem } from '@/features/active-users/data/active-users.types';

function item(id: string, occurredAt: string): ActivityFeedItem {
  return {
    id,
    userId: 'user-1',
    displayName: 'User',
    type: 'LOGIN',
    screen: null,
    message: `Event ${id}`,
    occurredAt,
  };
}

describe('mergeFeedItems', () => {
  it('dedupes by id and sorts newest first', () => {
    const merged = mergeFeedItems(
      [item('a', '2026-06-08T08:00:00.000Z'), item('b', '2026-06-08T07:00:00.000Z')],
      [item('a', '2026-06-08T08:00:00.000Z'), item('c', '2026-06-08T09:00:00.000Z')],
    );

    expect(merged.map((row) => row.id)).toEqual(['c', 'a', 'b']);
  });
});

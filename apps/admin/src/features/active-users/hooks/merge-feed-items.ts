import type { ActivityFeedItem } from '../data/active-users.types';

export const FEED_PAGE_LIMIT = 50;
export const FEED_ITEM_CAP = 500;

export function mergeFeedItems(
  existing: ActivityFeedItem[],
  incoming: ActivityFeedItem[],
): ActivityFeedItem[] {
  const byId = new Map<string, ActivityFeedItem>();
  for (const item of [...existing, ...incoming]) {
    byId.set(item.id, item);
  }
  return [...byId.values()]
    .sort((a, b) => b.occurredAt.localeCompare(a.occurredAt))
    .slice(0, FEED_ITEM_CAP);
}

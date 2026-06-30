import { ACTIVE_USERS_FEED_TYPE_OPTIONS } from '../constants/active-users-filters';

const FEED_TYPE_LABEL_KEY: Record<string, string> = Object.fromEntries(
  ACTIVE_USERS_FEED_TYPE_OPTIONS.filter((opt) => opt.value).map((opt) => [opt.value, opt.labelKey]),
);

export function feedTypeLabelKey(type: string): string {
  return FEED_TYPE_LABEL_KEY[type] ?? 'feed.types.unknown';
}

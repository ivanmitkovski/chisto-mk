import type { NewsCategory } from '@/data/news-posts';

export const NEWS_CATEGORIES: NewsCategory[] = [
  'release',
  'partnership',
  'community',
  'product',
  'media',
  'events',
  'impact',
];

export function parseNewsHubCategory(value: string | null | undefined): NewsCategory | undefined {
  if (!value) return undefined;
  return NEWS_CATEGORIES.includes(value as NewsCategory) ? (value as NewsCategory) : undefined;
}

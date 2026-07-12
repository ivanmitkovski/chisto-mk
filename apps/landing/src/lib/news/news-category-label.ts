import type { NewsCategory } from '@/data/news-posts';
import { NEWS_CATEGORIES } from './news-hub-params';

const KNOWN_CATEGORIES = new Set<string>(NEWS_CATEGORIES);

/**
 * Resolve a category display label from i18n.
 * Unknown values render as the raw string so a future category cannot crash the page.
 */
export function newsCategoryLabel(
  category: string,
  translateKnown: (category: NewsCategory) => string,
): string {
  if (KNOWN_CATEGORIES.has(category)) {
    return translateKnown(category as NewsCategory);
  }
  return category;
}

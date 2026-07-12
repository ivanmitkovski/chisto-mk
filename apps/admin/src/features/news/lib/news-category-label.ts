import type { NewsCategoryApi } from '../news-api-types';
import { NEWS_CATEGORIES } from '../types';

const KNOWN_CATEGORIES = new Set<string>(NEWS_CATEGORIES);

/** Resolve a category display label; unknown values render as the raw string. */
export function newsCategoryLabel(
  category: string,
  translateKnown: (category: NewsCategoryApi) => string,
): string {
  if (KNOWN_CATEGORIES.has(category)) {
    return translateKnown(category as NewsCategoryApi);
  }
  return category;
}

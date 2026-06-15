import type { HelpArticleSlug, HelpCategoryId } from "./help-catalog";

export type HelpTopicFilterItem = {
  slug: HelpArticleSlug;
  categoryId: HelpCategoryId;
  categoryLabel: string;
  cardTitle: string;
  cardSummary: string;
  readTime: string;
};

export type HelpSearchRankingOptions = {
  /** Earlier slugs get a small boost when relevance scores tie (e.g. hub featured topics). */
  pinnedSlugs?: readonly HelpArticleSlug[];
};

/** Case-fold and strip combining marks so queries match accented copy (e.g. cafe vs café). */
export function foldForSearch(value: string): string {
  return value.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase();
}

export function normalizeHelpSearchQuery(query: string): string {
  return foldForSearch(query.trim());
}

/**
 * Client-side filter: every non-empty word in the query must appear somewhere in
 * title, summary, or category label (case-insensitive).
 */
export function filterHelpTopics(items: readonly HelpTopicFilterItem[], query: string): HelpTopicFilterItem[] {
  const normalized = normalizeHelpSearchQuery(query);
  if (!normalized) {
    return [...items];
  }
  const words = normalized.split(/\s+/).filter((w) => w.length > 0);
  return items.filter((item) => {
    const slugWords = item.slug.replace(/-/g, " ");
    const haystack = foldForSearch(`${slugWords} ${item.cardTitle} ${item.cardSummary} ${item.categoryLabel}`);
    return words.every((w) => haystack.includes(w));
  });
}

function helpTopicMatchScore(item: HelpTopicFilterItem, words: readonly string[]): number {
  const slugWords = foldForSearch(item.slug.replace(/-/g, " "));
  const title = foldForSearch(item.cardTitle);
  const summary = foldForSearch(item.cardSummary);
  const cat = foldForSearch(item.categoryLabel);
  let score = 0;
  for (const w of words) {
    if (title.includes(w)) score += 12;
    if (summary.includes(w)) score += 5;
    if (cat.includes(w)) score += 4;
    if (slugWords.includes(w)) score += 3;
  }
  return score;
}

/** Sort filtered topics by lexical relevance (title > summary > category > slug words). */
export function rankHelpTopicsByQueryRelevance(
  items: readonly HelpTopicFilterItem[],
  query: string,
  options?: HelpSearchRankingOptions,
): HelpTopicFilterItem[] {
  const normalized = normalizeHelpSearchQuery(query);
  if (!normalized) {
    return [...items];
  }
  const words = normalized.split(/\s+/).filter((w) => w.length > 0);
  const pinned = options?.pinnedSlugs ?? [];
  return [...items].sort((a, b) => {
    const pinA = pinned.indexOf(a.slug);
    const pinB = pinned.indexOf(b.slug);
    const boostA = pinA >= 0 ? (pinned.length - pinA) * 3 : 0;
    const boostB = pinB >= 0 ? (pinned.length - pinB) * 3 : 0;
    const sa = helpTopicMatchScore(a, words) + boostA;
    const sb = helpTopicMatchScore(b, words) + boostB;
    return sb - sa || a.slug.localeCompare(b.slug);
  });
}

export function filterAndRankHelpTopics(
  items: readonly HelpTopicFilterItem[],
  query: string,
  options?: HelpSearchRankingOptions,
): HelpTopicFilterItem[] {
  const filtered = filterHelpTopics(items, query);
  const normalized = normalizeHelpSearchQuery(query);
  if (!normalized) {
    return filtered;
  }
  return rankHelpTopicsByQueryRelevance(filtered, query, options);
}

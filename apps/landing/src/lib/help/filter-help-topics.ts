import type { HelpArticleSlug, HelpCategoryId } from "./help-catalog";
import { HELP_SEARCH_SYNONYMS } from "./help-search-synonyms";

export type HelpTopicFilterItem = {
  slug: HelpArticleSlug;
  categoryId: HelpCategoryId;
  categoryLabel: string;
  cardTitle: string;
  cardSummary: string;
  readTime: string;
  /** Section titles + block text for body search (server-built). */
  searchText?: string;
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

function wordMatchesHaystack(word: string, haystack: string): boolean {
  if (haystack.includes(word)) return true;
  const synonyms = HELP_SEARCH_SYNONYMS[word];
  if (!synonyms) return false;
  return synonyms.some((syn) => haystack.includes(foldForSearch(syn)));
}

/**
 * Client-side filter: every non-empty word in the query must appear somewhere in
 * title, summary, category label, slug, or body (synonyms count as a match).
 */
export function filterHelpTopics(items: readonly HelpTopicFilterItem[], query: string): HelpTopicFilterItem[] {
  const normalized = normalizeHelpSearchQuery(query);
  if (!normalized) {
    return [...items];
  }
  const words = normalized.split(/\s+/).filter((w) => w.length > 0);
  return items.filter((item) => {
    const slugWords = item.slug.replace(/-/g, " ");
    const body = item.searchText ?? "";
    const haystack = foldForSearch(
      `${slugWords} ${item.cardTitle} ${item.cardSummary} ${item.categoryLabel} ${body}`,
    );
    return words.every((w) => wordMatchesHaystack(w, haystack));
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

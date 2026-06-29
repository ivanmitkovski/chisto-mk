import {
  fetchAllNewsSlugs,
  fetchNewsPostBySlug,
  fetchNewsPosts,
  fetchRelatedNewsPosts,
  NEWS_CATEGORY_FETCH_LIMIT,
  NEWS_HUB_PAGE_SIZE,
  type FetchNewsPostsOptions,
  type NewsCategory,
  type NewsPostsPage,
  type ResolvedNewsPost,
} from '@/lib/news/fetch-news';

export type { NewsCategory, ResolvedNewsPost, NewsPostsPage, FetchNewsPostsOptions };
export { NEWS_HUB_PAGE_SIZE, NEWS_CATEGORY_FETCH_LIMIT };

export async function getNewsPosts(
  locale: string,
  options?: FetchNewsPostsOptions,
): Promise<NewsPostsPage> {
  return fetchNewsPosts(locale, options);
}

export async function getLatestNewsPosts(locale: string, limit = 3): Promise<ResolvedNewsPost[]> {
  const { items } = await fetchNewsPosts(locale, { limit });
  return items;
}

export async function getNewsHubPosts(
  locale: string,
  page: number,
  category?: NewsCategory,
): Promise<NewsPostsPage> {
  return fetchNewsPosts(locale, {
    limit: NEWS_HUB_PAGE_SIZE,
    offset: (page - 1) * NEWS_HUB_PAGE_SIZE,
    ...(category ? { category } : {}),
  });
}

export async function getNewsPostBySlug(
  locale: string,
  slug: string,
): Promise<ResolvedNewsPost | null> {
  return fetchNewsPostBySlug(locale, slug);
}

export async function getRelatedNewsPosts(
  locale: string,
  slug: string,
): Promise<ResolvedNewsPost[]> {
  return fetchRelatedNewsPosts(locale, slug);
}

export async function getAllNewsSlugs(): Promise<string[]> {
  return fetchAllNewsSlugs();
}

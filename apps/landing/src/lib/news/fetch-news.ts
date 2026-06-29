import { resolvePreviewBlocks } from '@chisto/news-content/render';
import { chistoApiBase } from '@/lib/share-api';
import type { AppLocale } from '@/i18n/routing';
import {
  e2eNewsPostBySlug,
  e2eNewsPosts,
  e2eNewsSlugs,
  isE2eNewsFixtureEnabled,
} from './e2e-fixture';
import { NewsFetchError } from './news-fetch-error';

export type NewsCategory = 'release' | 'partnership' | 'community' | 'product';

import type { NewsBodyBlock as SharedNewsBodyBlock } from '@chisto/news-content';

export type NewsBodyBlock = SharedNewsBodyBlock & {
  url?: string | null;
  altText?: string | null;
};

export type ResolvedNewsBodyBlock = NewsBodyBlock;

export type ResolvedNewsPost = {
  slug: string;
  publishedAt: string;
  updatedAt?: string;
  category: NewsCategory;
  featured?: boolean;
  coverImage?: string;
  coverAltText?: string;
  title: string;
  excerpt: string;
  body: NewsBodyBlock[];
};

export type FetchNewsPostsOptions = {
  limit?: number;
  offset?: number;
  category?: NewsCategory;
};

type PublicListResponse = {
  items: Array<{
    slug: string;
    category: NewsCategory;
    publishedAt: string;
    title: string;
    excerpt: string;
    coverImageUrl: string | null;
    featured?: boolean;
  }>;
  total: number;
};

type SlugDateRow = { slug: string; updatedAt: string; publishedAt: string };
export type NewsPostsPage = {
  items: ResolvedNewsPost[];
  total: number;
};

export const NEWS_HUB_PAGE_SIZE = 9;
export const NEWS_CATEGORY_FETCH_LIMIT = 100;

type PublicPostResponse = {
  slug: string;
  category: NewsCategory;
  publishedAt: string;
  updatedAt?: string;
  title: string;
  excerpt: string;
  body: NewsBodyBlock[];
  coverImageUrl: string | null;
  media: Array<{ id: string; url: string | null; kind: string; altText?: Record<string, string> | null }>;
};

const REVALIDATE_SECONDS = 60;

function normalizeLocale(locale: string): AppLocale {
  if (locale === 'en' || locale === 'mk' || locale === 'sq') return locale;
  return 'en';
}

function enrichBodyBlocks(
  blocks: NewsBodyBlock[],
  media: PublicPostResponse['media'],
  locale: AppLocale,
): NewsBodyBlock[] {
  const mediaById = new Map(
    media.map((m) => [
      m.id,
      {
        url: m.url,
        altText: m.altText?.[locale] ?? m.altText?.en ?? null,
      },
    ]),
  );
  return resolvePreviewBlocks(blocks, mediaById);
}

function coverAltFromMedia(
  media: PublicPostResponse['media'],
  locale: AppLocale,
): string | undefined {
  const cover = media.find((m) => m.kind === 'cover');
  if (!cover?.altText) return undefined;
  return cover.altText[locale] ?? cover.altText.en;
}

export async function fetchNewsPosts(
  locale: string,
  options: FetchNewsPostsOptions = {},
): Promise<NewsPostsPage> {
  const limit = options.limit ?? 100;
  const offset = options.offset ?? 0;
  const category = options.category;
  if (isE2eNewsFixtureEnabled()) {
    const items = e2eNewsPosts(locale);
    const filtered = category ? items.filter((p) => p.category === category) : items;
    return { items: filtered, total: filtered.length };
  }
  const loc = normalizeLocale(locale);
  try {
    const params = new URLSearchParams({
      locale: loc,
      limit: String(limit),
      offset: String(offset),
    });
    if (category) params.set('category', category);
    const res = await fetch(`${chistoApiBase()}/news/posts?${params.toString()}`, {
      next: { revalidate: REVALIDATE_SECONDS, tags: ['news'] },
    });
    if (!res.ok) {
      throw new NewsFetchError(`News list request failed (${res.status})`);
    }
    const data = (await res.json()) as PublicListResponse;
    return {
      items: data.items.map((item) => ({
        slug: item.slug,
        publishedAt: item.publishedAt,
        category: item.category,
        title: item.title,
        excerpt: item.excerpt,
        body: [],
        ...(item.featured ? { featured: true } : {}),
        ...(item.coverImageUrl ? { coverImage: item.coverImageUrl } : {}),
      })),
      total: data.total,
    };
  } catch (error) {
    if (error instanceof NewsFetchError) throw error;
    throw new NewsFetchError();
  }
}

export async function fetchNewsPostBySlug(
  locale: string,
  slug: string,
): Promise<ResolvedNewsPost | null> {
  if (isE2eNewsFixtureEnabled()) {
    return e2eNewsPostBySlug(locale, slug);
  }
  const loc = normalizeLocale(locale);
  try {
    const res = await fetch(
      `${chistoApiBase()}/news/posts/${encodeURIComponent(slug)}?locale=${encodeURIComponent(loc)}`,
      { next: { revalidate: REVALIDATE_SECONDS, tags: ['news'] } },
    );
    if (res.status === 404) return null;
    if (!res.ok) {
      throw new NewsFetchError(`News post request failed (${res.status})`);
    }
    const data = (await res.json()) as PublicPostResponse;
    const coverAlt = coverAltFromMedia(data.media, loc);
    return {
      slug: data.slug,
      publishedAt: data.publishedAt,
      ...(data.updatedAt ? { updatedAt: data.updatedAt } : {}),
      category: data.category,
      title: data.title,
      excerpt: data.excerpt,
      body: enrichBodyBlocks(data.body, data.media, loc),
      ...(data.coverImageUrl ? { coverImage: data.coverImageUrl } : {}),
      ...(coverAlt ? { coverAltText: coverAlt } : {}),
    };
  } catch (error) {
    if (error instanceof NewsFetchError) throw error;
    throw new NewsFetchError();
  }
}

export async function fetchRelatedNewsPosts(
  locale: string,
  slug: string,
): Promise<ResolvedNewsPost[]> {
  if (isE2eNewsFixtureEnabled()) {
    return [];
  }
  const loc = normalizeLocale(locale);
  try {
    const res = await fetch(
      `${chistoApiBase()}/news/posts/${encodeURIComponent(slug)}/related?locale=${encodeURIComponent(loc)}`,
      { next: { revalidate: REVALIDATE_SECONDS, tags: ['news'] } },
    );
    if (res.status === 404) return [];
    if (!res.ok) {
      console.error(`fetchRelatedNewsPosts failed (${res.status}) for slug=${slug}`);
      return [];
    }
    const data = (await res.json()) as PublicListResponse;
    return data.items.map((item) => ({
      slug: item.slug,
      publishedAt: item.publishedAt,
      category: item.category,
      title: item.title,
      excerpt: item.excerpt,
      body: [],
      ...(item.featured ? { featured: true } : {}),
      ...(item.coverImageUrl ? { coverImage: item.coverImageUrl } : {}),
    }));
  } catch (error) {
    console.error('fetchRelatedNewsPosts network error', error);
    return [];
  }
}

export async function fetchAllNewsSlugs(): Promise<string[]> {
  if (isE2eNewsFixtureEnabled()) {
    return e2eNewsSlugs();
  }
  try {
    const res = await fetch(`${chistoApiBase()}/news/slugs`, {
      next: { revalidate: REVALIDATE_SECONDS, tags: ['news'] },
    });
    if (!res.ok) {
      if (res.status >= 500) {
        throw new NewsFetchError(`News slugs request failed (${res.status})`);
      }
      console.error(`fetchAllNewsSlugs failed (${res.status})`);
      return [];
    }
    return (await res.json()) as string[];
  } catch (error) {
    if (error instanceof NewsFetchError) throw error;
    console.error('fetchAllNewsSlugs network error', error);
    throw new NewsFetchError();
  }
}

export async function fetchNewsSlugDates(): Promise<Map<string, Date>> {
  if (isE2eNewsFixtureEnabled()) {
    return new Map(e2eNewsSlugs().map((slug) => [slug, new Date('2026-06-23')]));
  }
  try {
    const res = await fetch(`${chistoApiBase()}/news/slug-dates`, {
      next: { revalidate: REVALIDATE_SECONDS, tags: ['news'] },
    });
    if (!res.ok) {
      if (res.status >= 500) {
        throw new NewsFetchError(`News slug dates request failed (${res.status})`);
      }
      console.error(`fetchNewsSlugDates failed (${res.status})`);
      return new Map();
    }
    const data = (await res.json()) as SlugDateRow[];
    return new Map(data.map((item) => [item.slug, new Date(item.updatedAt)]));
  } catch (error) {
    if (error instanceof NewsFetchError) throw error;
    console.error('fetchNewsSlugDates network error', error);
    throw new NewsFetchError();
  }
}

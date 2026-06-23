import { chistoApiBase } from '@/lib/share-api';
import type { AppLocale } from '@/i18n/routing';
import {
  e2eNewsPostBySlug,
  e2eNewsPosts,
  e2eNewsSlugs,
  isE2eNewsFixtureEnabled,
} from './e2e-fixture';

export type NewsCategory = 'release' | 'partnership' | 'community' | 'product';

export type NewsBodyBlock =
  | { type: 'paragraph'; text: string }
  | { type: 'image'; mediaId: string; caption?: string; url?: string | null }
  | { type: 'video'; mediaId: string; caption?: string; url?: string | null };

export type ResolvedNewsPost = {
  slug: string;
  publishedAt: string;
  category: NewsCategory;
  coverImage?: string;
  title: string;
  excerpt: string;
  body: NewsBodyBlock[];
};

type PublicListResponse = {
  items: Array<{
    slug: string;
    category: NewsCategory;
    publishedAt: string;
    title: string;
    excerpt: string;
    coverImageUrl: string | null;
  }>;
};

type PublicPostResponse = {
  slug: string;
  category: NewsCategory;
  publishedAt: string;
  title: string;
  excerpt: string;
  body: NewsBodyBlock[];
  coverImageUrl: string | null;
  media: Array<{ id: string; url: string | null; kind: string }>;
};

const REVALIDATE_SECONDS = 60;

function normalizeLocale(locale: string): AppLocale {
  if (locale === 'en' || locale === 'mk' || locale === 'sq') return locale;
  return 'mk';
}

function enrichBodyBlocks(
  blocks: NewsBodyBlock[],
  media: PublicPostResponse['media'],
): NewsBodyBlock[] {
  const urlById = new Map(media.map((m) => [m.id, m.url]));
  return blocks.map((block) => {
    if (block.type === 'paragraph') return block;
    return { ...block, url: urlById.get(block.mediaId) ?? null };
  });
}

export async function fetchNewsPosts(locale: string): Promise<ResolvedNewsPost[]> {
  if (isE2eNewsFixtureEnabled()) {
    return e2eNewsPosts(locale);
  }
  const loc = normalizeLocale(locale);
  try {
    const res = await fetch(
      `${chistoApiBase()}/news/posts?locale=${encodeURIComponent(loc)}`,
      { next: { revalidate: REVALIDATE_SECONDS, tags: ['news'] } },
    );
    if (!res.ok) return [];
    const data = (await res.json()) as PublicListResponse;
    return data.items.map((item) => ({
      slug: item.slug,
      publishedAt: item.publishedAt,
      category: item.category,
      title: item.title,
      excerpt: item.excerpt,
      body: [],
      ...(item.coverImageUrl ? { coverImage: item.coverImageUrl } : {}),
    }));
  } catch {
    return [];
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
    if (!res.ok) return null;
    const data = (await res.json()) as PublicPostResponse;
    return {
      slug: data.slug,
      publishedAt: data.publishedAt,
      category: data.category,
      title: data.title,
      excerpt: data.excerpt,
      body: enrichBodyBlocks(data.body, data.media),
      ...(data.coverImageUrl ? { coverImage: data.coverImageUrl } : {}),
    };
  } catch {
    return null;
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
    if (!res.ok) return [];
    return (await res.json()) as string[];
  } catch {
    return [];
  }
}

import type { NewsCategory, NewsMedia, NewsMediaKind, NewsPost, NewsPostStatus } from '../../prisma-client';
import type {
  NewsCategoryApi,
  NewsMediaDto,
  NewsMediaKindApi,
  NewsPostAdminDto,
  NewsPostListItemPublicDto,
  NewsPostPublicDto,
  NewsPostStatusApi,
  NewsLocale,
  NewsTranslations,
} from '../types/news.types';
import { NEWS_LOCALES } from '../types/news.types';

const CATEGORY_TO_API: Record<NewsCategory, NewsCategoryApi> = {
  RELEASE: 'release',
  PARTNERSHIP: 'partnership',
  COMMUNITY: 'community',
  PRODUCT: 'product',
};

const CATEGORY_FROM_API: Record<NewsCategoryApi, NewsCategory> = {
  release: 'RELEASE',
  partnership: 'PARTNERSHIP',
  community: 'COMMUNITY',
  product: 'PRODUCT',
};

const STATUS_TO_API: Record<NewsPostStatus, NewsPostStatusApi> = {
  DRAFT: 'draft',
  SCHEDULED: 'scheduled',
  PUBLISHED: 'published',
  ARCHIVED: 'archived',
};

const MEDIA_KIND_TO_API: Record<NewsMediaKind, NewsMediaKindApi> = {
  COVER: 'cover',
  INLINE_IMAGE: 'inline_image',
  INLINE_VIDEO: 'inline_video',
};

export function categoryToApi(category: NewsCategory): NewsCategoryApi {
  return CATEGORY_TO_API[category];
}

export function categoryFromApi(category: NewsCategoryApi): NewsCategory {
  return CATEGORY_FROM_API[category];
}

export function statusToApi(status: NewsPostStatus): NewsPostStatusApi {
  return STATUS_TO_API[status];
}

export function parseTranslations(raw: unknown): NewsTranslations {
  if (raw == null || typeof raw !== 'object') {
    throw new Error('Invalid news translations');
  }
  const obj = raw as Record<string, unknown>;
  const out = {} as NewsTranslations;
  for (const locale of NEWS_LOCALES) {
    const entry = obj[locale];
    if (entry == null || typeof entry !== 'object') {
      throw new Error(`Missing news locale: ${locale}`);
    }
    const e = entry as Record<string, unknown>;
    out[locale] = {
      title: String(e.title ?? ''),
      excerpt: String(e.excerpt ?? ''),
      body: Array.isArray(e.body) ? (e.body as NewsTranslations[NewsLocale]['body']) : [],
    };
  }
  return out;
}

export function toMediaDto(
  media: NewsMedia,
  signedUrls: Map<string, string | null>,
): NewsMediaDto {
  return {
    id: media.id,
    kind: MEDIA_KIND_TO_API[media.kind],
    url: signedUrls.get(media.objectKey) ?? null,
    mimeType: media.mimeType,
    fileName: media.fileName,
    width: media.width,
    height: media.height,
    durationSeconds: media.durationSeconds,
    altText: (media.altText as NewsMediaDto['altText']) ?? null,
    sortOrder: media.sortOrder,
  };
}

export function toAdminDto(
  post: NewsPost & { media: NewsMedia[]; coverMedia?: NewsMedia | null },
  signedUrls: Map<string, string | null>,
): NewsPostAdminDto {
  const coverUrl =
    post.coverMedia != null ? (signedUrls.get(post.coverMedia.objectKey) ?? null) : null;
  return {
    id: post.id,
    slug: post.slug,
    category: categoryToApi(post.category),
    status: statusToApi(post.status),
    publishedAt: post.publishedAt?.toISOString() ?? null,
    scheduledAt: post.scheduledAt?.toISOString() ?? null,
    translations: parseTranslations(post.translations),
    coverMediaId: post.coverMediaId,
    coverImageUrl: coverUrl,
    media: post.media.map((m) => toMediaDto(m, signedUrls)),
    createdAt: post.createdAt.toISOString(),
    updatedAt: post.updatedAt.toISOString(),
    featured: post.featured,
    createdById: post.createdById,
    updatedById: post.updatedById,
  };
}

export function toPublicListItem(
  post: NewsPost & { coverMedia?: NewsMedia | null },
  locale: NewsLocale,
  signedUrls: Map<string, string | null>,
): NewsPostListItemPublicDto {
  const translations = parseTranslations(post.translations);
  const content = translations[locale];
  const coverUrl =
    post.coverMedia != null ? (signedUrls.get(post.coverMedia.objectKey) ?? null) : null;
  return {
    slug: post.slug,
    category: categoryToApi(post.category),
    publishedAt: post.publishedAt!.toISOString(),
    title: content.title,
    excerpt: content.excerpt,
    coverImageUrl: coverUrl,
    featured: post.featured,
  };
}

export function toPublicDto(
  post: NewsPost & { media: NewsMedia[]; coverMedia?: NewsMedia | null },
  locale: NewsLocale,
  signedUrls: Map<string, string | null>,
): NewsPostPublicDto {
  const translations = parseTranslations(post.translations);
  const content = translations[locale];
  const coverUrl =
    post.coverMedia != null ? (signedUrls.get(post.coverMedia.objectKey) ?? null) : null;
  return {
    slug: post.slug,
    category: categoryToApi(post.category),
    publishedAt: post.publishedAt!.toISOString(),
    title: content.title,
    excerpt: content.excerpt,
    body: content.body,
    coverImageUrl: coverUrl,
    media: post.media.map((m) => toMediaDto(m, signedUrls)),
  };
}

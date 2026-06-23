export const NEWS_LOCALES = ['en', 'mk', 'sq'] as const;
export type NewsLocale = (typeof NEWS_LOCALES)[number];

export type NewsBodyBlock =
  | { type: 'paragraph'; text: string }
  | { type: 'image'; mediaId: string; caption?: string }
  | { type: 'video'; mediaId: string; caption?: string };

export type NewsLocaleContent = {
  title: string;
  excerpt: string;
  body: NewsBodyBlock[];
};

export type NewsTranslations = Record<NewsLocale, NewsLocaleContent>;

export type NewsCategoryApi = 'release' | 'partnership' | 'community' | 'product';

export type NewsPostStatusApi = 'draft' | 'scheduled' | 'published' | 'archived';

export type NewsMediaKindApi = 'cover' | 'inline_image' | 'inline_video';

export type NewsMediaDto = {
  id: string;
  kind: NewsMediaKindApi;
  url: string | null;
  mimeType: string;
  fileName: string | null;
  width: number | null;
  height: number | null;
  durationSeconds: number | null;
  altText: Partial<Record<NewsLocale, string>> | null;
  sortOrder: number;
};

export type NewsPostAdminDto = {
  id: string;
  slug: string;
  category: NewsCategoryApi;
  status: NewsPostStatusApi;
  publishedAt: string | null;
  scheduledAt: string | null;
  translations: NewsTranslations;
  coverMediaId: string | null;
  coverImageUrl: string | null;
  media: NewsMediaDto[];
  createdAt: string;
  updatedAt: string;
};

export type NewsPostPublicDto = {
  slug: string;
  category: NewsCategoryApi;
  publishedAt: string;
  title: string;
  excerpt: string;
  body: NewsBodyBlock[];
  coverImageUrl: string | null;
  media: NewsMediaDto[];
};

export type NewsPostListItemPublicDto = {
  slug: string;
  category: NewsCategoryApi;
  publishedAt: string;
  title: string;
  excerpt: string;
  coverImageUrl: string | null;
};

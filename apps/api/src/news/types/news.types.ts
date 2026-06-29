export const NEWS_LOCALES = ['en', 'mk', 'sq'] as const;
export type NewsLocale = (typeof NEWS_LOCALES)[number];

export type NewsBodyBlock =
  | { id?: string; type: 'paragraph'; text: string; html?: string }
  | { id?: string; type: 'html'; html: string }
  | { id?: string; type: 'heading'; level: 2 | 3; text: string }
  | { id?: string; type: 'list'; ordered: boolean; items: string[] }
  | { id?: string; type: 'image'; mediaId: string; caption?: string }
  | { id?: string; type: 'video'; mediaId: string; caption?: string }
  | { id?: string; type: 'gallery'; items: Array<{ mediaId: string; caption?: string }> };

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
  featured: boolean;
  translations: NewsTranslations;
  coverMediaId: string | null;
  coverImageUrl: string | null;
  media: NewsMediaDto[];
  createdAt: string;
  updatedAt: string;
  createdById?: string | null;
  updatedById?: string | null;
  localeCompleteness?: Partial<Record<NewsLocale, boolean>>;
};

export type NewsPostPublicDto = {
  slug: string;
  category: NewsCategoryApi;
  publishedAt: string;
  updatedAt: string;
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
  featured: boolean;
};

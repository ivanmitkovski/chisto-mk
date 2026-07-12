export type {
  NewsBodyBlock,
  NewsParagraphBlock,
  NewsHtmlBlock,
  NewsHeadingBlock,
  NewsListBlock,
  NewsImageBlock,
  NewsVideoBlock,
  ResolvedNewsBodyBlock,
} from '@chisto/news-content';

export { createBlockId } from '@chisto/news-content';

export type NewsLocale = 'en' | 'mk' | 'sq';

export type NewsTranslations = Record<
  NewsLocale,
  {
    title: string;
    excerpt: string;
    body: import('@chisto/news-content').NewsBodyBlock[];
  }
>;

export type NewsCategoryApi =
  | 'release'
  | 'partnership'
  | 'community'
  | 'product'
  | 'media'
  | 'events'
  | 'impact';

export const NEWS_CATEGORY_API_VALUES: readonly NewsCategoryApi[] = [
  'release',
  'partnership',
  'community',
  'product',
  'media',
  'events',
  'impact',
] as const;

export type NewsPostStatusApi = 'draft' | 'scheduled' | 'published' | 'archived';

export type NewsMediaDto = {
  id: string;
  kind: 'cover' | 'inline_image' | 'inline_video';
  url: string | null;
  mimeType: string;
  fileName: string | null;
  width?: number | null;
  height?: number | null;
  altText?: Partial<Record<NewsLocale, string>> | null;
};

export type NewsPostAdminDto = {
  id: string;
  slug: string;
  category: NewsCategoryApi;
  status: NewsPostStatusApi;
  publishedAt: string | null;
  scheduledAt: string | null;
  featured?: boolean;
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

export type NewsListResponse = {
  items: NewsPostAdminDto[];
  total: number;
  countsByStatus: Record<string, number>;
  limit: number;
  offset: number;
};

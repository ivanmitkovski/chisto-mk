import type {
  NewsBodyBlock,
  NewsCategoryApi,
  NewsPostAdminDto,
  NewsPostStatusApi,
  NewsTranslations,
} from './news-api-types';

export type { NewsBodyBlock, NewsCategoryApi, NewsPostAdminDto, NewsPostStatusApi, NewsTranslations };

export type NewsPostFormValues = {
  slug: string;
  category: NewsCategoryApi;
  scheduledAt: string;
  translations: NewsTranslations;
};

export const NEWS_CATEGORIES: NewsCategoryApi[] = [
  'release',
  'partnership',
  'community',
  'product',
];

export const NEWS_LOCALES = ['en', 'mk', 'sq'] as const;
export type NewsFormLocale = (typeof NEWS_LOCALES)[number];

export function emptyTranslations(): NewsTranslations {
  const emptyBody: NewsBodyBlock[] = [{ type: 'paragraph', text: '' }];
  return {
    en: { title: '', excerpt: '', body: [...emptyBody] },
    mk: { title: '', excerpt: '', body: [...emptyBody] },
    sq: { title: '', excerpt: '', body: [...emptyBody] },
  };
}

export function postToFormValues(post: NewsPostAdminDto): NewsPostFormValues {
  return {
    slug: post.slug,
    category: post.category,
    scheduledAt: post.scheduledAt ?? '',
    translations: post.translations,
  };
}

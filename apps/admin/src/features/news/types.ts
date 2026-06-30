import { toDatetimeLocalValue } from '@/lib/datetime/datetime-local';
import { ensureBlocksHaveIds } from './lib/news-block-factory';
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
  featured: boolean;
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
  const emptyLocale = { title: '', excerpt: '', body: [] as NewsBodyBlock[] };
  return {
    en: { ...emptyLocale, body: [] },
    mk: { ...emptyLocale, body: [] },
    sq: { ...emptyLocale, body: [] },
  };
}

export function postToFormValues(post: NewsPostAdminDto): NewsPostFormValues {
  const translations = { ...post.translations };
  for (const locale of NEWS_LOCALES) {
    translations[locale] = {
      ...translations[locale],
      body: ensureBlocksHaveIds(translations[locale].body),
    };
  }
  return {
    slug: post.slug,
    category: post.category,
    scheduledAt: toDatetimeLocalValue(post.scheduledAt),
    featured: post.featured ?? false,
    translations,
  };
}

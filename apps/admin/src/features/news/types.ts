import type {
  NewsBodyBlock,
  NewsCategoryApi,
  NewsPostAdminDto,
  NewsPostStatusApi,
  NewsTranslations,
} from './news-api-types';
import { NEWS_CATEGORY_API_VALUES } from './news-api-types';

export type { NewsBodyBlock, NewsCategoryApi, NewsPostAdminDto, NewsPostStatusApi, NewsTranslations };

export type NewsPostFormValues = {
  slug: string;
  category: NewsCategoryApi;
  scheduledAt: string;
  featured: boolean;
  translations: NewsTranslations;
};

export const NEWS_CATEGORIES: readonly NewsCategoryApi[] = NEWS_CATEGORY_API_VALUES;

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

export { postToFormValues } from './lib/post-to-form-values';

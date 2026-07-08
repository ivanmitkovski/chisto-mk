import { toDatetimeLocalValue } from '@/lib/datetime/datetime-local';
import type { NewsPostAdminDto } from '../news-api-types';
import type { NewsPostFormValues } from '../types';
import { ensureBlocksHaveIds } from './news-block-factory';

const NEWS_LOCALES = ['en', 'mk', 'sq'] as const;

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

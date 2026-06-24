import type { NewsCategoryApi, NewsTranslations } from '../news-api-types';
import type { NewsLocale } from '../news-api-types';

type CreateNewsInput = {
  slug?: string;
  category: NewsCategoryApi;
  translations: NewsTranslations;
};

function fillLocale(translations: NewsTranslations, locale: NewsLocale, fallbackTitle: string) {
  const entry = translations[locale];
  const title = entry.title.trim() || fallbackTitle;
  const excerpt = entry.excerpt.trim() || title;
  if (entry.body.length > 0) {
    return { title, excerpt, body: entry.body };
  }
  return {
    title,
    excerpt,
    body: [{ type: 'paragraph' as const, text: title }],
  };
}

/** Build a create payload that satisfies strict and draft admin news APIs. */
export function buildCreateNewsInput(input: {
  slug?: string;
  category: NewsCategoryApi;
  translations: NewsTranslations;
}): CreateNewsInput {
  const enTitle = input.translations.en.title.trim() || 'Draft';
  const slug = input.slug?.trim();

  return {
    ...(slug ? { slug } : {}),
    category: input.category,
    translations: {
      en: fillLocale(input.translations, 'en', enTitle),
      mk: fillLocale(input.translations, 'mk', enTitle),
      sq: fillLocale(input.translations, 'sq', enTitle),
    },
  };
}

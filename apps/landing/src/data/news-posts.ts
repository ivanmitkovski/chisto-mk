import { locales, type AppLocale } from '@/i18n/routing';
import {
  fetchAllNewsSlugs,
  fetchNewsPostBySlug,
  fetchNewsPosts,
  fetchRelatedNewsPosts,
  type NewsCategory,
  type ResolvedNewsPost,
} from '@/lib/news/fetch-news';

export type { NewsCategory, ResolvedNewsPost };

const LOCALES = locales;

export async function getNewsPosts(locale: string): Promise<ResolvedNewsPost[]> {
  return fetchNewsPosts(locale);
}

export async function getNewsPostBySlug(
  locale: string,
  slug: string,
): Promise<ResolvedNewsPost | null> {
  return fetchNewsPostBySlug(locale, slug);
}

export async function getRelatedNewsPosts(
  locale: string,
  slug: string,
): Promise<ResolvedNewsPost[]> {
  return fetchRelatedNewsPosts(locale, slug);
}

export async function getAllNewsSlugs(): Promise<string[]> {
  return fetchAllNewsSlugs();
}

export async function getAllNewsStaticParams(): Promise<{ locale: AppLocale; slug: string }[]> {
  const slugs = await getAllNewsSlugs();
  const out: { locale: AppLocale; slug: string }[] = [];
  for (const locale of LOCALES) {
    for (const slug of slugs) {
      out.push({ locale, slug });
    }
  }
  return out;
}

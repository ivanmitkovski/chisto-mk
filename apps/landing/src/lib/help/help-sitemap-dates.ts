import type { HelpArticleSlug } from "./help-catalog";
import en from "../../../messages/en.json";
import mk from "../../../messages/mk.json";
import sq from "../../../messages/sq.json";

type ArticleDates = { dateModified?: string };

const HELP_MESSAGES = {
  en: en as { helpCentre?: { articles?: Record<string, ArticleDates> } },
  mk: mk as { helpCentre?: { articles?: Record<string, ArticleDates> } },
  sq: sq as { helpCentre?: { articles?: Record<string, ArticleDates> } },
};

function parseIsoDate(value: string | undefined): Date | undefined {
  if (value == null || value === "") return undefined;
  const ms = Date.parse(value);
  if (Number.isNaN(ms)) return undefined;
  return new Date(ms);
}

/** `lastModified` for a help article URL from messages `dateModified`, or fallback (typically build time). */
export function helpArticleLastModified(locale: string, slug: HelpArticleSlug, fallback: Date): Date {
  const pack = HELP_MESSAGES[locale as keyof typeof HELP_MESSAGES];
  const article = pack?.helpCentre?.articles?.[slug];
  return parseIsoDate(article?.dateModified) ?? fallback;
}

/** Latest `dateModified` among all help articles for a locale, for the hub `/help` URL. */
export function helpHubLastModified(locale: string, fallback: Date): Date {
  const pack = HELP_MESSAGES[locale as keyof typeof HELP_MESSAGES];
  const articles = pack?.helpCentre?.articles;
  if (!articles) return fallback;
  let maxMs = 0;
  for (const meta of Object.values(articles)) {
    const d = parseIsoDate(meta?.dateModified);
    if (d) maxMs = Math.max(maxMs, d.getTime());
  }
  return maxMs > 0 ? new Date(maxMs) : fallback;
}

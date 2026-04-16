import { Suspense } from "react";
import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/routing";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import {
  HELP_ARTICLE_SLUGS,
  helpArticleMeta,
  isHelpArticleSlug,
  type HelpArticleSlug,
} from "@/lib/help/help-catalog";
import type { HelpTopicFilterItem } from "@/lib/help/filter-help-topics";
import { helpArticleSectionSchema } from "@/lib/help/help-messages-schema";
import { estimateReadMinutesFromSections } from "@/lib/help/help-read-time";
import { HelpCentreHubAnalytics } from "./HelpCentreHubAnalytics";
import { HelpSearch } from "./HelpSearch";

export async function HelpHub() {
  const th = await getTranslations("helpCentre.hub");
  const t = await getTranslations("helpCentre");
  const tCats = await getTranslations("helpCentre.categories");
  const tCommon = await getTranslations("helpCentre.common");

  const topics: HelpTopicFilterItem[] = HELP_ARTICLE_SLUGS.map((slug) => {
    const meta = helpArticleMeta(slug);
    if (!meta) {
      throw new Error(`Missing help article meta for slug: ${slug}`);
    }
    const sectionsRaw = t.raw(`articles.${slug}.sections`);
    const sectionsParsed = helpArticleSectionSchema.array().safeParse(sectionsRaw);
    if (!sectionsParsed.success) {
      throw new Error(`Invalid help article sections for ${slug}: ${sectionsParsed.error.message}`);
    }
    const minutes = estimateReadMinutesFromSections(sectionsParsed.data);
    return {
      slug,
      categoryId: meta.categoryId,
      categoryLabel: tCats(`${meta.categoryId}.label`),
      cardTitle: t(`articles.${slug}.cardTitle`),
      cardSummary: t(`articles.${slug}.cardSummary`),
      readTime: tCommon("readTimeFormatted", { minutes }),
    };
  });

  const featuredSlugsRaw = th.raw("featuredSlugs");
  const featuredSlugs: HelpArticleSlug[] = Array.isArray(featuredSlugsRaw)
    ? featuredSlugsRaw.filter((s): s is HelpArticleSlug => typeof s === "string" && isHelpArticleSlug(s))
    : [];

  return (
    <Section className="relative overflow-hidden mesh-section-faq">
      <HelpCentreHubAnalytics />
      <div className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-20" aria-hidden />
      <Container className="relative z-10 pb-10 md:pb-14">
        <div className="space-y-3 md:space-y-4">
          <h1 className="text-balance text-section-title font-bold tracking-tight text-gray-900">{th("title")}</h1>
          <p className="max-w-2xl text-pretty text-lg leading-relaxed text-gray-600 md:text-xl md:leading-relaxed">
            {th("subtitle")}
          </p>
          <p className="text-sm font-medium tabular-nums text-gray-500">
            {th("catalogMetrics", { count: HELP_ARTICLE_SLUGS.length })}
          </p>
        </div>

        <div className="mt-8 rounded-2xl border border-gray-200/80 bg-white/80 p-5 shadow-sm md:mt-10 md:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-gray-500">{th("featuredTitle")}</p>
          <p className="mt-2 max-w-2xl text-sm leading-relaxed text-gray-600 md:text-[0.9375rem]">{th("featuredIntro")}</p>
          <ul className="mt-5 flex flex-wrap gap-3">
            {featuredSlugs.map((slug) => (
              <li key={slug}>
                <Link
                  href={`/help/${slug}`}
                  className="inline-flex items-center rounded-full border border-primary/25 bg-primary/[0.06] px-4 py-2 text-sm font-semibold text-primary shadow-sm transition-colors hover:border-primary/40 hover:bg-primary/[0.1]"
                >
                  {t(`articles.${slug}.cardTitle`)}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        <div className="mt-8 md:mt-10">
          <Suspense
            fallback={<div className="h-32 max-w-xl animate-pulse rounded-2xl bg-gray-100/80" aria-hidden />}
          >
            <HelpSearch topics={topics} pinnedSlugs={featuredSlugs} />
          </Suspense>
        </div>
      </Container>
    </Section>
  );
}

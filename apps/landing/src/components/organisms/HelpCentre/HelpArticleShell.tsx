import { getLocale, getTranslations } from "next-intl/server";
import { Link } from "@/i18n/routing";
import { HelpRelatedAnalyticsLink } from "@/components/organisms/HelpCentre/HelpRelatedAnalyticsLink";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { HELP_ARTICLES_HOWTO_JSONLD, helpRelatedSlugs, type HelpArticleSlug } from "@/lib/help/help-catalog";
import { helpHowToStepsFromBlocks } from "@/lib/help/help-howto";
import { getSiteUrl } from "@/lib/site-url";
import { helpArticleMessageSchema } from "@/lib/help/help-messages-schema";
import { estimateReadMinutesFromSections } from "@/lib/help/help-read-time";
import { HelpArticleSectionHeading } from "./HelpArticleSectionHeading";
import { HelpArticleBlocks } from "./HelpArticleBlocks";
import { HelpArticleFeedback } from "./HelpArticleFeedback";
import { HelpArticleJsonLd } from "./HelpArticleJsonLd";
import { HelpArticleReadingProgress } from "./HelpArticleReadingProgress";
import { HelpToc } from "./HelpToc";

export async function HelpArticleShell({ slug }: { slug: HelpArticleSlug }) {
  const t = await getTranslations("helpCentre");
  const tCommon = await getTranslations("helpCentre.common");
  const locale = await getLocale();
  const articleRaw = t.raw(`articles.${slug}`);
  const articleParsed = helpArticleMessageSchema.safeParse(articleRaw);
  if (!articleParsed.success) {
    throw new Error(`Invalid help article for ${slug}: ${articleParsed.error.message}`);
  }
  const { sections, title, lastUpdated, lastReviewed, cardSummary, datePublished, dateModified } =
    articleParsed.data;
  const readMinutes = estimateReadMinutesFromSections(sections);
  const pageUrl = `${getSiteUrl()}/${locale}/help/${slug}`;

  const tocItems = sections.map((s) => ({ id: s.id, title: s.title }));
  const howToSteps = HELP_ARTICLES_HOWTO_JSONLD.includes(slug) ? helpHowToStepsFromBlocks(sections) : undefined;
  const siteBase = getSiteUrl();
  const breadcrumb = [
    { name: tCommon("breadcrumbHome"), item: `${siteBase}/${locale}` },
    { name: tCommon("breadcrumbHelp"), item: `${siteBase}/${locale}/help` },
    { name: title, item: pageUrl },
  ] as const;

  return (
    <Section className="relative overflow-hidden mesh-section-faq print:bg-white">
      <div className="print:hidden">
        <HelpArticleReadingProgress />
      </div>
      <HelpArticleJsonLd
        pageUrl={pageUrl}
        locale={locale}
        headline={title}
        description={cardSummary}
        publisherName={tCommon("publisherName")}
        publisherUrl={siteBase}
        {...(datePublished != null ? { datePublished } : {})}
        {...(dateModified != null ? { dateModified } : {})}
        breadcrumb={breadcrumb}
        {...(howToSteps != null && howToSteps.length >= 2 ? { howToSteps } : {})}
      />
      <div className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-20 print:hidden" aria-hidden />
      <Container className="relative z-10 pb-10 md:pb-14">
        <nav aria-label="Breadcrumb" className="text-sm text-gray-600 print:hidden">
          <ol className="flex flex-wrap items-center gap-x-2 gap-y-1">
            <li>
              <Link href="/" className="font-medium text-primary transition-colors hover:text-primary/85">
                {tCommon("breadcrumbHome")}
              </Link>
            </li>
            <li className="text-gray-400" aria-hidden>
              /
            </li>
            <li>
              <Link href="/help" className="font-medium text-primary transition-colors hover:text-primary/85">
                {tCommon("breadcrumbHelp")}
              </Link>
            </li>
            <li className="text-gray-400" aria-hidden>
              /
            </li>
            <li className="max-w-[min(100%,20rem)] truncate text-gray-700" aria-current="page">
              {title}
            </li>
          </ol>
        </nav>

        <article className="mt-6 min-w-0 md:mt-8 lg:grid lg:grid-cols-[minmax(10.5rem,12.5rem)_minmax(0,1fr)] lg:items-start lg:gap-10 xl:gap-14">
          <div className="flex flex-col gap-6 md:gap-8 lg:contents">
            <aside className="print:hidden lg:min-w-0">
              <HelpToc
                items={tocItems}
                ariaLabel={tCommon("tocLabel")}
                mobileTriggerLabel={tCommon("tocMobileTrigger")}
              />
            </aside>

            <div className="min-w-0 max-w-[min(42rem,100%)] lg:pt-0">
              <header className="lg:sticky lg:top-20 lg:z-[11] lg:-mx-2 lg:mb-2 lg:rounded-2xl lg:border lg:border-gray-200/60 lg:bg-white/90 lg:px-4 lg:py-4 lg:shadow-sm lg:backdrop-blur-md lg:print:static lg:print:border-0 lg:print:bg-transparent lg:print:p-0 lg:print:shadow-none">
                <h1 className="text-balance text-section-title font-bold tracking-tight text-gray-900">{title}</h1>
                <p className="mt-4 text-sm text-gray-500 md:text-[0.9375rem]">
                  <span className="font-medium text-gray-600">{tCommon("lastUpdatedPrefix")}</span>{" "}
                  <span className="tabular-nums text-gray-700">{lastUpdated}</span>
                  <span className="mx-2 text-gray-300">·</span>
                  <span className="font-medium text-gray-600">{tCommon("lastReviewedPrefix")}</span>{" "}
                  <span className="tabular-nums text-gray-700">{lastReviewed}</span>
                  <span className="mx-2 text-gray-300">·</span>
                  <span className="tabular-nums text-gray-700">{tCommon("readTimeFormatted", { minutes: readMinutes })}</span>
                </p>
              </header>

              <div className="mt-8 flex flex-col gap-10 md:mt-10 md:gap-12">
                {sections.map((section) => (
                  <section
                    key={section.id}
                    id={section.id}
                    className="scroll-mt-32 border-b border-gray-200/70 pb-10 last:border-0 last:pb-0 md:scroll-mt-36 md:pb-12 print:border-gray-300 print:pb-8"
                  >
                    <HelpArticleSectionHeading
                      sectionId={section.id}
                      title={section.title}
                      copyLabel={tCommon("copySectionLinkAria")}
                      copiedLabel={tCommon("sectionLinkCopied")}
                    />
                    <HelpArticleBlocks
                      blocks={section.blocks}
                      calloutTipLabel={tCommon("calloutTip")}
                      calloutNoteLabel={tCommon("calloutNote")}
                    />
                  </section>
                ))}
              </div>

              <div className="mt-12 print:hidden md:mt-14">
                <HelpArticleFeedback slug={slug} />
              </div>

              <section
                className="mt-12 border-t border-gray-200/80 pt-10 md:mt-14 md:pt-12 print:break-inside-avoid"
                aria-labelledby="help-related"
              >
                <h2 id="help-related" className="text-lg font-bold tracking-tight text-gray-900 md:text-xl">
                  {tCommon("relatedTitle")}
                </h2>
                <ul className="mt-5 grid gap-3 sm:grid-cols-2 md:mt-6 md:gap-4">
                  {helpRelatedSlugs(slug).map((rel) => (
                    <li key={rel}>
                      <HelpRelatedAnalyticsLink
                        slug={rel}
                        fromSlug={slug}
                        className="block h-full rounded-2xl border border-gray-200/90 bg-white/90 p-4 shadow-sm transition-[border-color,box-shadow] hover:border-primary/25 hover:shadow-md md:p-5"
                      >
                        <span className="font-semibold tracking-tight text-gray-900">{t(`articles.${rel}.cardTitle`)}</span>
                        <p className="mt-2 text-sm leading-relaxed text-gray-600">{t(`articles.${rel}.cardSummary`)}</p>
                      </HelpRelatedAnalyticsLink>
                    </li>
                  ))}
                </ul>
              </section>
            </div>
          </div>
        </article>
      </Container>
    </Section>
  );
}

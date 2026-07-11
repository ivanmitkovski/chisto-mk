import { extractNewsHeadingToc } from "@chisto/news-content/render";
import { Link, type AppLocale } from "@/i18n/routing";
import type { ResolvedNewsPost } from "@/data/news-posts";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { ReadingProgressBar } from "@/components/molecules/ReadingProgressBar";
import { NewsArticleCover } from "./NewsArticleCover";
import { NewsBackLink } from "./NewsReadMoreLink";
import { NewsArticleBlocks } from "./NewsArticleBlocks";
import { NewsArticleToc } from "./NewsArticleToc";
import { NewsRelatedPosts } from "./NewsRelatedPosts";
import { NewsShareBar, type NewsShareBarCopy } from "./NewsShareBar";

const DATE_LOCALES: Record<AppLocale, string> = {
  mk: "mk-MK",
  en: "en-GB",
  sq: "sq-AL",
};

function formatNewsDate(locale: AppLocale, iso: string): string {
  return new Intl.DateTimeFormat(DATE_LOCALES[locale], { dateStyle: "long" }).format(
    new Date(iso),
  );
}

function showUpdatedDate(publishedAt: string, updatedAt?: string): boolean {
  if (!updatedAt) return false;
  const published = new Date(publishedAt).getTime();
  const updated = new Date(updatedAt).getTime();
  return updated - published > 60_000;
}

export type NewsArticleCopy = {
  badge: string;
  backToNews: string;
  readingTime: string;
  share: NewsShareBarCopy;
  relatedTitle: string;
  imageUnavailable: string;
  videoUnavailable: string;
  galleryClose: string;
  galleryPrevious: string;
  galleryNext: string;
  galleryUnavailable: string;
  galleryAriaLabel: string;
  viewImage: string;
  breadcrumbHome: string;
  breadcrumbNews: string;
  breadcrumbAriaLabel: string;
  updatedLabel: (date: string) => string;
  tocLabel: string;
  tocMobileTrigger: string;
};

type NewsArticleProps = {
  locale: AppLocale;
  post: ResolvedNewsPost;
  relatedPosts: ResolvedNewsPost[];
  copy: NewsArticleCopy;
  categoryLabel: string;
  relatedCategoryLabel: (category: ResolvedNewsPost["category"]) => string;
  jsonLd: string;
};

export function NewsArticle({
  locale,
  post,
  relatedPosts,
  copy,
  categoryLabel,
  relatedCategoryLabel,
  jsonLd,
}: NewsArticleProps) {
  const showUpdated = showUpdatedDate(post.publishedAt, post.updatedAt);
  const tocItems = extractNewsHeadingToc(post.body);
  const coverCaption =
    post.coverAltText &&
    post.coverAltText.trim() !== "" &&
    post.coverAltText.trim().toLowerCase() !== post.title.trim().toLowerCase()
      ? post.coverAltText.trim()
      : null;

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: jsonLd }}
      />
      <div className="print:hidden">
        <ReadingProgressBar />
      </div>
      <Section className="relative overflow-hidden mesh-section-how print:bg-white">
        <div
          className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-25 print:hidden"
          aria-hidden
        />
        <Container className="relative z-10 pb-10 md:pb-14">
          <nav aria-label={copy.breadcrumbAriaLabel} className="text-sm text-gray-600 print:hidden">
            <ol className="flex flex-wrap items-center gap-x-2 gap-y-1">
              <li>
                <Link href="/" className="font-medium text-primary transition-colors hover:text-primary/85">
                  {copy.breadcrumbHome}
                </Link>
              </li>
              <li className="text-gray-400" aria-hidden>
                /
              </li>
              <li>
                <Link href="/news" className="font-medium text-primary transition-colors hover:text-primary/85">
                  {copy.breadcrumbNews}
                </Link>
              </li>
              <li className="text-gray-400" aria-hidden>
                /
              </li>
              <li className="max-w-[min(100%,20rem)] truncate text-gray-700" aria-current="page">
                {post.title}
              </li>
            </ol>
          </nav>

          <article className="mt-6 min-w-0 md:mt-8">
            <header>
              <div className="flex flex-wrap items-center gap-2 gap-y-2">
                <Badge variant="about">{copy.badge}</Badge>
                <span className="inline-flex rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide text-primary-800">
                  {categoryLabel}
                </span>
                <time
                  className="text-sm tabular-nums text-gray-500 md:text-[0.9375rem]"
                  dateTime={post.publishedAt}
                >
                  {formatNewsDate(locale, post.publishedAt)}
                </time>
                {showUpdated && post.updatedAt ? (
                  <>
                    <span className="text-sm text-gray-300" aria-hidden>
                      ·
                    </span>
                    <time
                      className="text-sm tabular-nums text-gray-500 md:text-[0.9375rem]"
                      dateTime={post.updatedAt}
                    >
                      {copy.updatedLabel(formatNewsDate(locale, post.updatedAt))}
                    </time>
                  </>
                ) : null}
                <span className="text-sm text-gray-300" aria-hidden>
                  ·
                </span>
                <span className="text-sm tabular-nums text-gray-500 md:text-[0.9375rem]">
                  {copy.readingTime}
                </span>
              </div>
              <h1 className="mt-4 max-w-copy text-balance text-section-title font-bold tracking-tight text-gray-900">
                {post.title}
              </h1>
              <p className="mt-6 max-w-2xl text-pretty text-lg leading-relaxed text-gray-600">
                {post.excerpt}
              </p>
            </header>

            {post.coverImage ? (
              <NewsArticleCover
                src={post.coverImage}
                alt={post.coverAltText ?? post.title}
                caption={coverCaption}
                viewImageLabel={copy.viewImage}
                closeLabel={copy.galleryClose}
                dialogLabel={copy.galleryAriaLabel}
              />
            ) : null}

            <NewsShareBar
              title={post.title}
              excerpt={post.excerpt}
              copy={copy.share}
              className={post.coverImage ? "mt-8" : "mt-10"}
            />

            <NewsArticleToc
              items={tocItems}
              ariaLabel={copy.tocLabel}
              mobileTriggerLabel={copy.tocMobileTrigger}
            />

            <div className="prose-news mt-10 max-w-copy md:mt-12">
              <NewsArticleBlocks
                body={post.body}
                imageUnavailableLabel={copy.imageUnavailable}
                videoUnavailableLabel={copy.videoUnavailable}
                galleryUnavailableLabel={copy.galleryUnavailable}
                galleryCloseLabel={copy.galleryClose}
                galleryPreviousLabel={copy.galleryPrevious}
                galleryNextLabel={copy.galleryNext}
                galleryAriaLabel={copy.galleryAriaLabel}
              />
            </div>

            <div className="mt-12 max-w-copy border-t border-gray-200/70 pt-8 md:mt-14 md:pt-10">
              <NewsShareBar
                title={post.title}
                excerpt={post.excerpt}
                copy={copy.share}
                variant="compact"
                className="mt-0"
              />
            </div>

            <NewsRelatedPosts
              posts={relatedPosts}
              title={copy.relatedTitle}
              categoryLabel={relatedCategoryLabel}
              fromSlug={post.slug}
            />

            <p className="mt-14 border-t border-gray-200/70 pt-10 print:hidden">
              <NewsBackLink href="/news">{copy.backToNews}</NewsBackLink>
            </p>
          </article>
        </Container>
      </Section>
    </>
  );
}

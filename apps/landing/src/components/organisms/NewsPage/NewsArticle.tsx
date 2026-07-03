import Image from "next/image";
import { NEWS_COVER_FRAME_SURFACE } from "@/lib/images/news-cover-display";
import { shouldUseUnoptimizedNewsImage, newsImageObjectFitClass } from "@/lib/images/news-image-optimization";
import { Link, type AppLocale } from "@/i18n/routing";
import type { ResolvedNewsPost } from "@/data/news-posts";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { NewsBackLink } from "./NewsReadMoreLink";
import { NewsArticleBlocks } from "./NewsArticleBlocks";
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
  breadcrumbHome: string;
  breadcrumbNews: string;
  breadcrumbAriaLabel: string;
  updatedLabel: (date: string) => string;
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

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: jsonLd }}
      />
      <Section className="relative overflow-hidden mesh-section-how">
        <div
          className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-25"
          aria-hidden
        />
        <Container className="relative z-10">
          <nav aria-label={copy.breadcrumbAriaLabel} className="text-sm text-gray-600">
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

          <div className="mt-6 flex flex-wrap items-center gap-2 gap-y-2">
            <Badge>{copy.badge}</Badge>
            <span className="inline-flex rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide text-primary-800">
              {categoryLabel}
            </span>
            <time className="text-sm text-gray-500" dateTime={post.publishedAt}>
              {formatNewsDate(locale, post.publishedAt)}
            </time>
            {showUpdated && post.updatedAt ? (
              <>
                <span className="text-sm text-gray-400" aria-hidden>
                  ·
                </span>
                <time className="text-sm text-gray-500" dateTime={post.updatedAt}>
                  {copy.updatedLabel(formatNewsDate(locale, post.updatedAt))}
                </time>
              </>
            ) : null}
            <span className="text-sm text-gray-400" aria-hidden>
              ·
            </span>
            <span className="text-sm text-gray-500">{copy.readingTime}</span>
          </div>
          <h1 className="mt-4 max-w-copy text-section-title font-bold text-gray-900">{post.title}</h1>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-gray-600">{post.excerpt}</p>

          <NewsShareBar title={post.title} excerpt={post.excerpt} copy={copy.share} />

          {post.coverImage ? (
            <div className={`relative mt-10 aspect-[21/9] max-w-4xl overflow-hidden rounded-2xl border border-gray-200/90 ${NEWS_COVER_FRAME_SURFACE} shadow-sm`}>
              <Image
                src={post.coverImage}
                alt={post.coverAltText ?? post.title}
                fill
                className={newsImageObjectFitClass(post.coverImage, "cover")}
                sizes="(min-width: 896px) 896px, 100vw"
                priority
                unoptimized={shouldUseUnoptimizedNewsImage(post.coverImage)}
              />
            </div>
          ) : null}

          <div className="prose-news mt-12 max-w-copy">
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

          <NewsRelatedPosts
            posts={relatedPosts}
            title={copy.relatedTitle}
            categoryLabel={relatedCategoryLabel}
            fromSlug={post.slug}
          />

          <p className="mt-14 border-t border-gray-200/90 pt-10">
            <NewsBackLink href="/news">{copy.backToNews}</NewsBackLink>
          </p>
        </Container>
      </Section>
    </>
  );
}

import Image from "next/image";
import type { AppLocale } from "@/i18n/routing";
import type { ResolvedNewsPost } from "@/data/mock-news";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { NewsBackLink } from "./NewsReadMoreLink";

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

export type NewsArticleCopy = {
  badge: string;
  backToNews: string;
};

type NewsArticleProps = {
  locale: AppLocale;
  post: ResolvedNewsPost;
  copy: NewsArticleCopy;
  categoryLabel: string;
  jsonLd: string;
};

export function NewsArticle({ locale, post, copy, categoryLabel, jsonLd }: NewsArticleProps) {
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
          <p>
            <NewsBackLink href="/news">{copy.backToNews}</NewsBackLink>
          </p>
          <div className="mt-6 flex flex-wrap items-center gap-2 gap-y-2">
            <Badge>{copy.badge}</Badge>
            <span className="inline-flex rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide text-primary-800">
              {categoryLabel}
            </span>
            <time className="text-sm text-gray-500" dateTime={post.publishedAt}>
              {formatNewsDate(locale, post.publishedAt)}
            </time>
          </div>
          <h1 className="mt-4 max-w-copy text-section-title font-bold text-gray-900">{post.title}</h1>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-gray-600">{post.excerpt}</p>

          {post.coverImage ? (
            <div className="relative mt-10 aspect-[21/9] max-w-4xl overflow-hidden rounded-2xl border border-gray-200/90 bg-gray-100 shadow-sm">
              <Image
                src={post.coverImage}
                alt=""
                fill
                className="object-cover"
                sizes="(min-width: 896px) 896px, 100vw"
                priority
                unoptimized
              />
            </div>
          ) : null}

          <div className="prose-news mt-12 max-w-copy">
            {post.body.map((paragraph, i) => (
              <p key={i} className="mt-6 first:mt-0 leading-relaxed text-gray-700">
                {paragraph}
              </p>
            ))}
          </div>

          <p className="mt-14 border-t border-gray-200/90 pt-10">
            <NewsBackLink href="/news">{copy.backToNews}</NewsBackLink>
          </p>
        </Container>
      </Section>
    </>
  );
}

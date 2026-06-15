import Image from "next/image";
import { Link, type AppLocale } from "@/i18n/routing";
import type { NewsCategory, ResolvedNewsPost } from "@/data/mock-news";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { NewsReadMoreLink } from "./NewsReadMoreLink";

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

export type NewsLandingCopy = {
  badge: string;
  title: string;
  lead: string;
  demoNotice: string;
  featuredLabel: string;
  latestHeading: string;
  readMore: string;
  emptyTitle: string;
  emptyBody: string;
  contactCta: string;
};

type NewsLandingProps = {
  locale: AppLocale;
  posts: ResolvedNewsPost[];
  copy: NewsLandingCopy;
  categoryLabel: (category: NewsCategory) => string;
};

function CategoryPill({ label }: { label: string }) {
  return (
    <span className="inline-flex rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide text-primary-800 ring-1 ring-primary/15">
      {label}
    </span>
  );
}

export function NewsLanding({ locale, posts, copy, categoryLabel }: NewsLandingProps) {
  const [featured, ...rest] = posts;

  return (
    <Section className="relative overflow-hidden mesh-section-how">
        <div
          className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-25"
          aria-hidden
        />
        <Container className="relative z-10">
          <Badge>{copy.badge}</Badge>
          <h1 className="mt-3 max-w-copy text-section-title font-bold text-gray-900">{copy.title}</h1>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-gray-600">{copy.lead}</p>

          <p
            className="mt-8 max-w-2xl rounded-xl border border-amber-200/90 bg-amber-50/90 px-4 py-3 text-sm leading-relaxed text-amber-950 shadow-sm backdrop-blur-sm"
            role="note"
          >
            {copy.demoNotice}
          </p>

          {posts.length === 0 ? (
            <div className="mt-14 max-w-2xl rounded-2xl border border-gray-200/90 bg-white/70 p-8 shadow-sm backdrop-blur-sm md:p-10">
              <h2 className="text-lg font-bold text-gray-900">{copy.emptyTitle}</h2>
              <p className="mt-3 leading-relaxed text-gray-600">{copy.emptyBody}</p>
              <p className="mt-6">
                <Link
                  href="/contact"
                  className="text-sm font-semibold text-primary underline-offset-4 transition-colors hover:text-primary-600 hover:underline"
                >
                  {copy.contactCta}
                </Link>
              </p>
            </div>
          ) : (
            <div className="mt-14 space-y-12">
              <div>
                <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">
                  {copy.featuredLabel}
                </p>
                <article className="group mt-4 overflow-hidden rounded-2xl border border-gray-200/90 bg-white/80 shadow-sm ring-1 ring-black/[0.04] backdrop-blur-sm transition-[border-color,box-shadow,ring-color] duration-300 hover:border-primary/25 hover:shadow-lg hover:ring-primary/20 md:grid md:grid-cols-2 md:gap-0">
                  <Link
                    href={`/news/${featured.slug}`}
                    className="relative block aspect-[4/3] overflow-hidden bg-gray-100 md:aspect-auto md:min-h-[280px]"
                  >
                    {featured.coverImage ? (
                      <Image
                        src={featured.coverImage}
                        alt=""
                        fill
                        className="object-cover transition-transform duration-500 ease-out group-hover:scale-[1.02]"
                        sizes="(min-width: 768px) 50vw, 100vw"
                        unoptimized
                      />
                    ) : (
                      <div className="absolute inset-0 bg-gradient-to-br from-primary/15 to-gray-100 transition-transform duration-500 ease-out group-hover:scale-[1.02]" />
                    )}
                  </Link>
                  <div className="flex flex-col justify-center p-8 md:p-10">
                    <div className="flex flex-wrap items-center gap-2 gap-y-1">
                      <CategoryPill label={categoryLabel(featured.category)} />
                      <time
                        className="text-sm text-gray-500"
                        dateTime={featured.publishedAt}
                      >
                        {formatNewsDate(locale, featured.publishedAt)}
                      </time>
                    </div>
                    <h2 className="mt-4 text-xl font-bold text-gray-900 md:text-2xl">
                      <Link
                        href={`/news/${featured.slug}`}
                        className="transition-colors hover:text-primary-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
                      >
                        {featured.title}
                      </Link>
                    </h2>
                    <p className="mt-3 leading-relaxed text-gray-600">{featured.excerpt}</p>
                    <div className="mt-6">
                      <NewsReadMoreLink href={`/news/${featured.slug}`}>
                        {copy.readMore}
                      </NewsReadMoreLink>
                    </div>
                  </div>
                </article>
              </div>

              {rest.length > 0 ? (
                <div>
                  <h2 className="text-xs font-semibold uppercase tracking-wider text-gray-500">
                    {copy.latestHeading}
                  </h2>
                  <ul className="mt-6 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                    {rest.map((post) => (
                      <li key={post.slug}>
                        <article className="group flex h-full flex-col overflow-hidden rounded-2xl border border-gray-200/90 bg-white/80 shadow-sm ring-1 ring-black/[0.04] backdrop-blur-sm transition-[border-color,box-shadow,ring-color] duration-300 hover:border-primary/25 hover:shadow-lg hover:ring-primary/15">
                          <Link
                            href={`/news/${post.slug}`}
                            className="relative block aspect-[16/10] shrink-0 overflow-hidden bg-gray-100"
                          >
                            {post.coverImage ? (
                              <Image
                                src={post.coverImage}
                                alt=""
                                fill
                                className="object-cover transition-transform duration-500 ease-out group-hover:scale-[1.02]"
                                sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
                                unoptimized
                              />
                            ) : (
                              <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-gray-50 transition-transform duration-500 ease-out group-hover:scale-[1.02]" />
                            )}
                          </Link>
                          <div className="flex flex-1 flex-col p-6">
                            <div className="flex flex-wrap items-center gap-2 gap-y-1">
                              <CategoryPill label={categoryLabel(post.category)} />
                              <time
                                className="text-xs text-gray-500"
                                dateTime={post.publishedAt}
                              >
                                {formatNewsDate(locale, post.publishedAt)}
                              </time>
                            </div>
                            <h3 className="mt-3 text-base font-bold text-gray-900">
                              <Link
                                href={`/news/${post.slug}`}
                                className="transition-colors hover:text-primary-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
                              >
                                {post.title}
                              </Link>
                            </h3>
                            <p className="mt-2 flex-1 text-sm leading-relaxed text-gray-600">
                              {post.excerpt}
                            </p>
                            <div className="mt-4">
                              <NewsReadMoreLink href={`/news/${post.slug}`}>
                                {copy.readMore}
                              </NewsReadMoreLink>
                            </div>
                          </div>
                        </article>
                      </li>
                    ))}
                  </ul>
                </div>
              ) : null}
            </div>
          )}
        </Container>
      </Section>
  );
}

import Image from "next/image";
import { shouldUseUnoptimizedNewsImage } from "@/lib/images/news-image-optimization";
import { getTranslations } from "next-intl/server";
import { Link, type AppLocale } from "@/i18n/routing";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { isLaunchPageVisible } from "@/config/launch";
import { getLatestNewsPosts, type NewsCategory } from "@/data/news-posts";
import { NewsFetchError } from "@/lib/news/news-fetch-error";
import { EmptyStatePanel } from "@/components/molecules/EmptyStatePanel";
import { PageErrorPanel } from "@/components/molecules/PageErrorPanel";
import { NewsReadMoreLink } from "@/components/organisms/NewsPage/NewsReadMoreLink";

const DATE_LOCALES: Record<AppLocale, string> = {
  mk: "mk-MK",
  en: "en-GB",
  sq: "sq-AL",
};

function formatNewsDate(locale: AppLocale, iso: string): string {
  return new Intl.DateTimeFormat(DATE_LOCALES[locale], { dateStyle: "medium" }).format(
    new Date(iso),
  );
}

type LatestNewsSectionProps = {
  locale: AppLocale;
};

export async function LatestNewsSection({ locale }: LatestNewsSectionProps) {
  if (!isLaunchPageVisible("news")) return null;

  let posts: Awaited<ReturnType<typeof getLatestNewsPosts>>;
  let fetchFailed = false;
  try {
    posts = await getLatestNewsPosts(locale, 3);
  } catch (error) {
    if (error instanceof NewsFetchError) {
      fetchFailed = true;
      posts = [];
    } else {
      throw error;
    }
  }

  const t = await getTranslations("homeLatestNews");

  if (fetchFailed) {
    return (
      <Section className="relative overflow-hidden mesh-section-features">
        <Container className="relative z-10">
          <Badge>{t("badge")}</Badge>
          <h2 className="mt-3 text-section-title font-bold text-gray-900">{t("title")}</h2>
          <div className="mt-8">
            <PageErrorPanel
              title={t("errorTitle")}
              body={t("errorBody")}
              contactHref="/contact"
              contactLabel={t("errorContact")}
            />
          </div>
        </Container>
      </Section>
    );
  }

  if (posts.length === 0) {
    return (
      <Section className="relative overflow-hidden mesh-section-features">
        <Container className="relative z-10">
          <Badge>{t("badge")}</Badge>
          <h2 className="mt-3 text-section-title font-bold text-gray-900">{t("title")}</h2>
          <div className="mt-8">
            <EmptyStatePanel title={t("emptyTitle")} body={t("emptyBody")} ctaHref="/news" ctaLabel={t("viewAll")} />
          </div>
        </Container>
      </Section>
    );
  }

  const categoryLabel = (category: NewsCategory) => t(`category.${category}`);

  return (
    <Section className="relative overflow-hidden mesh-section-features">
      <div className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-20" aria-hidden />
      <Container className="relative z-10">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <Badge>{t("badge")}</Badge>
            <h2 className="mt-3 text-section-title font-bold text-gray-900">{t("title")}</h2>
          </div>
          <Link
            href="/news"
            className="text-sm font-semibold text-primary underline-offset-4 transition-colors hover:text-primary-600 hover:underline"
          >
            {t("viewAll")}
          </Link>
        </div>
        <ul className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {posts.map((post) => (
            <li key={post.slug}>
              <article className="group flex h-full flex-col overflow-hidden rounded-2xl border border-gray-200/90 bg-white/80 shadow-sm ring-1 ring-black/[0.04] backdrop-blur-sm transition-[border-color,box-shadow,ring-color] duration-300 hover:border-primary/25 hover:shadow-lg hover:ring-primary/15">
                <Link
                  href={`/news/${post.slug}`}
                  className="relative block aspect-[16/10] shrink-0 overflow-hidden bg-gray-100"
                  aria-label={post.title}
                >
                  {post.coverImage ? (
                    <Image
                      src={post.coverImage}
                      alt={post.title}
                      fill
                      className="object-cover transition-transform duration-500 ease-out group-hover:scale-[1.02]"
                      sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
                      unoptimized={shouldUseUnoptimizedNewsImage(post.coverImage)}
                    />
                  ) : (
                    <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-gray-50" />
                  )}
                </Link>
                <div className="flex flex-1 flex-col p-6">
                  <div className="flex flex-wrap items-center gap-2 gap-y-1">
                    <span className="inline-flex rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide text-primary-800 ring-1 ring-primary/15">
                      {categoryLabel(post.category)}
                    </span>
                    <time className="text-xs text-gray-500" dateTime={post.publishedAt}>
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
                  <p className="mt-2 flex-1 text-sm leading-relaxed text-gray-600 line-clamp-3">
                    {post.excerpt}
                  </p>
                  <div className="mt-4">
                    <NewsReadMoreLink href={`/news/${post.slug}`}>{t("readMore")}</NewsReadMoreLink>
                  </div>
                </div>
              </article>
            </li>
          ))}
        </ul>
      </Container>
    </Section>
  );
}

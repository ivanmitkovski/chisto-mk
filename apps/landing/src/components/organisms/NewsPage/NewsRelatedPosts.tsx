import Image from "next/image";
import { newsImageObjectFitClass, shouldUseUnoptimizedNewsImage } from "@/lib/images/news-image-optimization";
import type { ResolvedNewsPost } from "@/data/news-posts";
import { NewsRelatedAnalyticsLink } from "./NewsRelatedAnalyticsLink";

type NewsRelatedPostsProps = {
  posts: ResolvedNewsPost[];
  title: string;
  categoryLabel: (category: ResolvedNewsPost["category"]) => string;
  fromSlug: string;
};

export function NewsRelatedPosts({ posts, title, categoryLabel, fromSlug }: NewsRelatedPostsProps) {
  if (posts.length === 0) return null;

  return (
    <section
      className="mt-14 border-t border-gray-200/90 pt-12 md:mt-16 md:pt-14"
      aria-labelledby="news-related"
    >
      <h2 id="news-related" className="text-lg font-bold tracking-tight text-gray-900 md:text-xl">
        {title}
      </h2>
      <ul className="mt-5 grid gap-3 sm:grid-cols-2 md:mt-6 md:gap-4">
        {posts.map((post) => (
          <li key={post.slug}>
            <NewsRelatedAnalyticsLink
              href={`/news/${post.slug}`}
              slug={post.slug}
              fromSlug={fromSlug}
              className="group flex h-full gap-4 rounded-2xl border border-gray-200/90 bg-white/90 p-4 shadow-sm transition-[border-color,box-shadow] hover:border-primary/25 hover:shadow-md md:p-5"
            >
              {post.coverImage ? (
                <div className="relative h-16 w-20 shrink-0 overflow-hidden rounded-xl bg-gray-100 md:h-[4.5rem] md:w-24">
                  <Image
                    src={post.coverImage}
                    alt={post.title}
                    fill
                    className={`${newsImageObjectFitClass(post.coverImage)} transition-transform duration-300 group-hover:scale-[1.02]`}
                    sizes="96px"
                    unoptimized={shouldUseUnoptimizedNewsImage(post.coverImage)}
                  />
                </div>
              ) : (
                <div
                  className="h-16 w-20 shrink-0 rounded-xl bg-gradient-to-br from-primary/15 to-gray-100 md:h-[4.5rem] md:w-24"
                  aria-hidden
                />
              )}
              <div className="min-w-0 flex-1">
                <span className="inline-flex rounded-full bg-primary/10 px-2 py-0.5 text-[0.6875rem] font-semibold uppercase tracking-wide text-primary-800">
                  {categoryLabel(post.category)}
                </span>
                <span className="mt-2 block font-semibold tracking-tight text-gray-900 transition-colors group-hover:text-primary-700">
                  {post.title}
                </span>
                <p className="mt-2 line-clamp-2 text-sm leading-relaxed text-gray-600">{post.excerpt}</p>
              </div>
            </NewsRelatedAnalyticsLink>
          </li>
        ))}
      </ul>
    </section>
  );
}

import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";

function SkeletonBar({ className }: { className?: string }) {
  return <div className={`animate-pulse rounded-lg bg-gray-200/90 ${className ?? ""}`} />;
}

/**
 * Avoid next-intl server APIs here — Suspense fallbacks can run outside
 * setRequestLocale() and trigger DYNAMIC_SERVER_USAGE.
 */
export default function NewsArticleLoading() {
  return (
    <Section className="relative overflow-hidden mesh-section-how" aria-busy="true">
      <span className="sr-only">Loading</span>
      <Container className="relative z-10 pb-10 md:pb-14">
        <SkeletonBar className="h-5 w-32" />
        <div className="mt-6 flex flex-wrap gap-2 md:mt-8">
          <SkeletonBar className="h-6 w-16 rounded-full" />
          <SkeletonBar className="h-6 w-24 rounded-full" />
          <SkeletonBar className="h-5 w-28" />
        </div>
        <SkeletonBar className="mt-4 h-10 w-full max-w-3xl" />
        <SkeletonBar className="mt-6 h-5 w-full max-w-2xl" />
        <SkeletonBar className="mt-3 h-5 w-4/5 max-w-2xl" />
        <SkeletonBar className="mt-10 aspect-[21/9] max-w-4xl rounded-2xl" />
        <div className="mt-8 flex gap-3">
          <SkeletonBar className="h-10 w-28 rounded-full" />
          <SkeletonBar className="h-10 w-24 rounded-full" />
        </div>
        <div className="prose-news mt-10 max-w-copy space-y-6 md:mt-12">
          {Array.from({ length: 4 }).map((_, i) => (
            <SkeletonBar key={i} className="h-4 w-full" />
          ))}
          <SkeletonBar className="h-4 w-5/6" />
        </div>
      </Container>
    </Section>
  );
}

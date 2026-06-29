import { getTranslations } from "next-intl/server";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";

function SkeletonBar({ className }: { className?: string }) {
  return <div className={`animate-pulse rounded-lg bg-gray-200/90 ${className ?? ""}`} />;
}

export default async function NewsArticleLoading() {
  const t = await getTranslations("newsPage");
  return (
    <Section className="relative overflow-hidden mesh-section-how" aria-busy="true">
      <span className="sr-only">{t("articleLoadingLabel")}</span>
      <Container className="relative z-10">
        <SkeletonBar className="h-5 w-32" />
        <div className="mt-6 flex flex-wrap gap-2">
          <SkeletonBar className="h-6 w-16 rounded-full" />
          <SkeletonBar className="h-6 w-24 rounded-full" />
          <SkeletonBar className="h-5 w-28" />
        </div>
        <SkeletonBar className="mt-4 h-10 w-full max-w-3xl" />
        <SkeletonBar className="mt-6 h-5 w-full max-w-2xl" />
        <SkeletonBar className="mt-3 h-5 w-4/5 max-w-2xl" />
        <div className="mt-8 flex gap-3">
          <SkeletonBar className="h-10 w-28 rounded-full" />
          <SkeletonBar className="h-10 w-24 rounded-full" />
        </div>
        <SkeletonBar className="mt-10 aspect-[21/9] max-w-4xl rounded-2xl" />
        <div className="prose-news mt-12 max-w-copy space-y-6">
          {Array.from({ length: 4 }).map((_, i) => (
            <SkeletonBar key={i} className="h-4 w-full" />
          ))}
          <SkeletonBar className="h-4 w-5/6" />
        </div>
      </Container>
    </Section>
  );
}

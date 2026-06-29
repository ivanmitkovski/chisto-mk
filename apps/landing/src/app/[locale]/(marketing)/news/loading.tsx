import { getTranslations } from "next-intl/server";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";

function SkeletonBar({ className }: { className?: string }) {
  return <div className={`animate-pulse rounded-lg bg-gray-200/90 ${className ?? ""}`} />;
}

export default async function NewsHubLoading() {
  const t = await getTranslations("newsPage");
  return (
    <Section className="relative overflow-hidden mesh-section-how" aria-busy="true">
      <span className="sr-only">{t("loadingLabel")}</span>
      <Container className="relative z-10">
        <SkeletonBar className="h-6 w-20" />
        <SkeletonBar className="mt-3 h-10 w-full max-w-xl" />
        <SkeletonBar className="mt-6 h-5 w-full max-w-2xl" />
        <SkeletonBar className="mt-6 h-5 w-2/3 max-w-2xl" />
        <div className="mt-8 flex flex-wrap gap-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <SkeletonBar key={i} className="h-7 w-24 rounded-full" />
          ))}
        </div>
        <div className="mt-14 space-y-12">
          <div>
            <SkeletonBar className="h-4 w-24" />
            <div className="mt-4 overflow-hidden rounded-2xl border border-gray-200/90 md:grid md:grid-cols-2">
              <SkeletonBar className="aspect-[4/3] rounded-none md:aspect-auto md:min-h-[280px]" />
              <div className="space-y-4 p-8 md:p-10">
                <SkeletonBar className="h-5 w-32" />
                <SkeletonBar className="h-8 w-full" />
                <SkeletonBar className="h-4 w-full" />
                <SkeletonBar className="h-4 w-5/6" />
                <SkeletonBar className="h-5 w-28" />
              </div>
            </div>
          </div>
          <ul className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <li key={i} className="overflow-hidden rounded-2xl border border-gray-200/90">
                <SkeletonBar className="aspect-[16/10] rounded-none" />
                <div className="space-y-3 p-6">
                  <SkeletonBar className="h-4 w-28" />
                  <SkeletonBar className="h-5 w-full" />
                  <SkeletonBar className="h-4 w-full" />
                  <SkeletonBar className="h-4 w-4/5" />
                </div>
              </li>
            ))}
          </ul>
        </div>
      </Container>
    </Section>
  );
}

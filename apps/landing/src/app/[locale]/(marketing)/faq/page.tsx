import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { CTASection } from "@/components/organisms/CTASection";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";

type Props = { params: Promise<{ locale: string }> };

type FaqEntry = { title: string; content: string };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  return buildMarketingMetadata({
    locale,
    path: "/faq",
    title: t("faq.title"),
    description: t("faq.description"),
    siteName: t("siteName"),
  });
}

export default async function FaqPage({ params }: Props) {
  const { locale } = await params;
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const tFaq = await getTranslations({ locale, namespace: "faq" });
  const items = tFaq.raw("items") as FaqEntry[];

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    name: tMeta("faq.title"),
    description: tMeta("faq.description"),
    mainEntity: items.map((item) => ({
      "@type": "Question",
      name: item.title,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.content,
      },
    })),
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <Section className="relative overflow-hidden mesh-section-faq">
        <div
          className="pointer-events-none absolute inset-0 pattern-diagonal-soft opacity-[0.35]"
          aria-hidden
        />
        <Container className="relative z-10 max-w-3xl">
          <Badge>{tFaq("badge")}</Badge>
          <h1 className="mt-3 text-balance text-section-title font-bold tracking-tight text-gray-900">
            {tFaq("title")}
          </h1>
          <p className="mt-4 text-base leading-relaxed text-gray-600 md:text-lg">
            {tMeta("faq.description")}
          </p>

          <div className="mt-10 flex flex-col gap-3 md:mt-12 md:gap-4">
            {items.map((item, index) => (
              <details
                key={index}
                className="group rounded-2xl border border-gray-200/90 bg-white/95 p-5 shadow-[var(--shadow-card)] ring-1 ring-black/[0.03] open:shadow-[var(--shadow-lift)] md:p-6"
              >
                <summary className="cursor-pointer list-none text-lg font-bold tracking-tight text-gray-900 marker:content-none [&::-webkit-details-marker]:hidden">
                  <span className="flex items-start justify-between gap-4">
                    <span>{item.title}</span>
                    <span
                      aria-hidden
                      className="mt-1 shrink-0 text-primary transition-transform duration-200 group-open:rotate-45"
                    >
                      +
                    </span>
                  </span>
                </summary>
                <p className="mt-4 text-sm leading-relaxed text-gray-600 md:text-[0.9375rem]">
                  {item.content}
                </p>
              </details>
            ))}
          </div>
        </Container>
      </Section>
      <CTASection />
    </>
  );
}

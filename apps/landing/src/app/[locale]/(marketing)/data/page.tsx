import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { Badge } from "@/components/atoms/Badge";
import { buttonVariants } from "@/components/atoms/Button";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { LegalPageNav } from "@/components/molecules/LegalPageNav";
import type { LegalSection } from "@/components/organisms/LegalLayout";
import { type AppLocale } from "@/i18n/routing";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";
import { buildWebPageJsonLd } from "@/lib/seo/webpage-json-ld";
import { getDataRequestChannelHref } from "@/lib/data-request-url";
import { getPublicLegalValue } from "@/lib/legal/legal-public-config";
import { LegalRichBody } from "@/lib/legal/legal-rich-body";
import {
  getLegalPlaceholderMap,
  substituteLegalSections,
  substituteLegalText,
} from "@/lib/legal/substitute-placeholders";
import { cn } from "@/lib/utils/cn";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  return buildMarketingMetadata({
    locale,
    path: "/data",
    title: t("data.title"),
    description: t("data.description"),
    siteName: t("siteName"),
  });
}

export default async function DataPage({ params }: Props) {
  const { locale } = await params;
  const appLocale = locale as AppLocale;
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const t = await getTranslations("dataPage");
  const map = getLegalPlaceholderMap(appLocale);
  const href = getDataRequestChannelHref(
    getPublicLegalValue(process.env.NEXT_PUBLIC_DATA_REQUEST_URL, "dataRequestUrl"),
  );
  const sections = substituteLegalSections(t.raw("sections") as LegalSection[], map);
  const jsonLd = buildWebPageJsonLd({
    locale,
    path: "/data",
    name: tMeta("data.title"),
    description: tMeta("data.description"),
    siteName: tMeta("siteName"),
  });

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <Section className="relative overflow-hidden mesh-section-features">
        <div className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-30" aria-hidden />
        <Container className="relative z-10 max-w-[min(42rem,calc(100%-1.5rem))] pb-8 md:pb-10">
          <Badge>{t("badge")}</Badge>
          <h1 className="mt-4 text-balance text-section-title font-bold tracking-tight text-gray-900">
            {t("title")}
          </h1>
          <p className="mt-4 text-sm text-gray-500">
            <span className="font-medium text-gray-600">{t("lastUpdatedLabel")}</span>{" "}
            <span className="tabular-nums text-gray-700">
              {substituteLegalText(t("lastUpdated"), map)}
            </span>
          </p>

          <div className="mt-8 text-lg leading-relaxed text-gray-600 md:text-[1.0625rem]">
            <LegalRichBody body={substituteLegalText(t("lead"), map)} className="flex flex-col gap-4" />
          </div>

          <section
            id="account-deletion"
            className="mt-14 scroll-mt-28 border-b border-gray-200/70 pb-14 md:mt-16 md:scroll-mt-32 md:pb-16"
          >
            <h2 className="text-balance text-xl font-bold tracking-tight text-gray-900 md:text-2xl">
              {t("requestTitle")}
            </h2>
            <div className="mt-5 text-[0.9375rem] leading-relaxed text-gray-700 md:mt-6 md:text-base">
              <LegalRichBody body={substituteLegalText(t("requestIntro"), map)} />
            </div>
            <div className="mt-6">
              {href ? (
                <a
                  href={href}
                  className={cn(
                    buttonVariants({ variant: "primary", size: "lg" }),
                    "shadow-md shadow-primary/25",
                  )}
                >
                  {t("requestCta")}
                </a>
              ) : (
                <p className="rounded-xl border border-amber-200/90 bg-amber-50/80 p-4 text-sm text-amber-950">
                  {t("requestMissing")}
                </p>
              )}
            </div>
          </section>

          <div className="mt-14 flex flex-col gap-14 md:mt-16 md:gap-16">
            {sections.map((s, i) => (
              <section
                key={i}
                className="scroll-mt-28 border-b border-gray-200/70 pb-14 last:border-0 last:pb-0 md:scroll-mt-32 md:pb-16"
              >
                <h2 className="text-balance text-xl font-bold tracking-tight text-gray-900 md:text-2xl">
                  {s.title}
                </h2>
                <div className="mt-5 text-[0.9375rem] md:mt-6 md:text-base">
                  <LegalRichBody body={s.body} />
                </div>
              </section>
            ))}
          </div>

          <LegalPageNav className="mt-14 md:mt-16" />
        </Container>
      </Section>
    </>
  );
}

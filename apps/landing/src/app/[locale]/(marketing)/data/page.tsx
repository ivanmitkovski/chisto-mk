import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/routing";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { buttonVariants } from "@/components/atoms/Button";
import { cn } from "@/lib/utils/cn";
import { getDataRequestChannelHref } from "@/lib/data-request-url";
import { routing } from "@/i18n/routing";
import type { LegalSection } from "@/components/organisms/LegalLayout";
import { LegalRichBody } from "@/lib/legal/legal-rich-body";
import {
  getLegalPlaceholderMap,
  substituteLegalSections,
  substituteLegalText,
} from "@/lib/legal/substitute-placeholders";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("data.title");
  const description = t("data.description");
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/data`]),
  ) as Record<string, string>;

  return {
    title,
    description,
    alternates: { languages },
    openGraph: {
      title,
      description,
      type: "website",
      locale: locale === "mk" ? "mk_MK" : locale === "sq" ? "sq_AL" : "en_US",
      siteName: t("siteName"),
    },
    twitter: { card: "summary_large_image", title, description },
  };
}

export default async function DataPage() {
  const t = await getTranslations("dataPage");
  const map = getLegalPlaceholderMap();
  const href = getDataRequestChannelHref(process.env.NEXT_PUBLIC_DATA_REQUEST_URL);
  const sections = substituteLegalSections(t.raw("sections") as LegalSection[], map);

  return (
    <Section className="relative overflow-hidden mesh-section-features">
      <div className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-30" aria-hidden />
      <Container className="relative z-10 max-w-[min(42rem,calc(100%-1.5rem))] pb-8 md:pb-10">
        <Badge>{t("badge")}</Badge>
        <h1 className="mt-4 text-balance text-section-title font-bold tracking-tight text-gray-900">
          {t("title")}
        </h1>
        <p className="mt-4 text-sm text-gray-500">
          <span className="font-medium text-gray-600">{t("lastUpdatedLabel")}</span>{" "}
          <span className="tabular-nums text-gray-700">{t("lastUpdated")}</span>
        </p>

        <div
          className="mt-8 rounded-2xl border border-amber-200/90 bg-amber-50/90 p-5 text-amber-950 shadow-sm shadow-amber-900/5 md:p-6"
          role="note"
        >
          <p className="text-sm font-semibold tracking-tight text-amber-950">
            {substituteLegalText(t("noticeTitle"), map)}
          </p>
          <div className="mt-3 text-sm leading-relaxed text-amber-950/95">
            <LegalRichBody
              body={substituteLegalText(t("noticeBody"), map)}
              className="flex flex-col gap-3"
              linkClassName="font-semibold text-amber-900 underline decoration-amber-700/45 underline-offset-2 transition-colors hover:decoration-amber-800"
            />
          </div>
        </div>

        <div className="mt-8 text-lg leading-relaxed text-gray-600 md:text-[1.0625rem]">
          <LegalRichBody body={substituteLegalText(t("lead"), map)} className="flex flex-col gap-4" />
        </div>

        <section className="mt-14 scroll-mt-28 border-b border-gray-200/70 pb-14 md:mt-16 md:scroll-mt-32 md:pb-16">
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

        <nav className="mt-14 flex flex-wrap gap-x-6 gap-y-3 border-t border-gray-200/80 pt-10 text-sm md:mt-16">
          <Link href="/privacy" className="font-medium text-primary underline-offset-4 hover:underline">
            {t("linkPrivacy")}
          </Link>
          <Link href="/cookies" className="font-medium text-primary underline-offset-4 hover:underline">
            {t("linkCookies")}
          </Link>
          <Link href="/terms" className="font-medium text-primary underline-offset-4 hover:underline">
            {t("linkTerms")}
          </Link>
        </nav>
      </Container>
    </Section>
  );
}

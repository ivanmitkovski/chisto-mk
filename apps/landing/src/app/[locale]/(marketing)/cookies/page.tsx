import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { LegalLayout, type LegalSection } from "@/components/organisms/LegalLayout";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { LegalRichBody } from "@/lib/legal/legal-rich-body";
import {
  getLegalPlaceholderMap,
  substituteCookieRows,
  substituteLegalSections,
  substituteLegalText,
} from "@/lib/legal/substitute-placeholders";
import { routing } from "@/i18n/routing";

type CookieRow = {
  name: string;
  provider: string;
  purpose: string;
  duration: string;
  type: string;
};

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("cookies.title");
  const description = t("cookies.description");
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/cookies`]),
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

export default async function CookiesPage() {
  const t = await getTranslations("cookiesPage");
  const map = getLegalPlaceholderMap();
  const sections = substituteLegalSections(t.raw("sections") as LegalSection[], map);
  const rows = substituteCookieRows(t.raw("cookieRows") as CookieRow[], map);
  const effectiveLabel = t("effectiveDateLabel").trim();
  const effectiveRaw = t("effectiveDate").trim();
  const showEffectiveDate = effectiveLabel.length > 0 && effectiveRaw.length > 0;

  return (
    <>
      <LegalLayout
        badge={t("badge")}
        title={t("title")}
        lastUpdatedLabel={t("lastUpdatedLabel")}
        lastUpdated={substituteLegalText(t("lastUpdated"), map)}
        {...(showEffectiveDate
          ? {
              effectiveDateLabel: effectiveLabel,
              effectiveDate: substituteLegalText(effectiveRaw, map),
            }
          : {})}
        noticeTitle={substituteLegalText(t("noticeTitle"), map)}
        noticeBody={substituteLegalText(t("noticeBody"), map)}
        sections={sections}
      />
      <Section className="relative -mt-6 overflow-hidden pb-16 pt-2 mesh-section-faq md:-mt-8">
        <Container className="relative z-10 max-w-[min(42rem,calc(100%-1.5rem))]">
          <div className="border-t border-gray-200/70 pt-12 md:pt-14">
            <h2 className="text-balance text-xl font-bold tracking-tight text-gray-900 md:text-2xl">
              {substituteLegalText(t("tableTitle"), map)}
            </h2>
            <div className="mt-5 text-sm leading-relaxed text-gray-600 md:mt-6 md:text-[0.9375rem]">
              <LegalRichBody
                body={substituteLegalText(t("tableIntro"), map)}
                className="flex flex-col gap-4"
              />
            </div>
            <div className="mt-8 overflow-x-auto rounded-2xl border border-gray-200/90 bg-white/90 shadow-sm shadow-gray-900/[0.04] ring-1 ring-black/[0.03]">
              <table className="w-full min-w-[36rem] border-collapse text-left text-sm">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50/95">
                    <th className="px-4 py-3.5 text-xs font-semibold uppercase tracking-wide text-gray-600 md:px-5 md:text-[0.8125rem]">
                      {t("colName")}
                    </th>
                    <th className="px-4 py-3.5 text-xs font-semibold uppercase tracking-wide text-gray-600 md:px-5 md:text-[0.8125rem]">
                      {t("colProvider")}
                    </th>
                    <th className="px-4 py-3.5 text-xs font-semibold uppercase tracking-wide text-gray-600 md:px-5 md:text-[0.8125rem]">
                      {t("colPurpose")}
                    </th>
                    <th className="px-4 py-3.5 text-xs font-semibold uppercase tracking-wide text-gray-600 md:px-5 md:text-[0.8125rem]">
                      {t("colDuration")}
                    </th>
                    <th className="px-4 py-3.5 text-xs font-semibold uppercase tracking-wide text-gray-600 md:px-5 md:text-[0.8125rem]">
                      {t("colType")}
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {rows.map((row, i) => (
                    <tr
                      key={i}
                      className="transition-colors odd:bg-white even:bg-gray-50/40 hover:bg-primary/[0.03]"
                    >
                      <td className="px-4 py-3.5 align-top font-medium text-gray-900 md:px-5">
                        {row.name}
                      </td>
                      <td className="px-4 py-3.5 align-top text-gray-700 md:px-5">{row.provider}</td>
                      <td className="px-4 py-3.5 align-top text-gray-700 md:px-5">{row.purpose}</td>
                      <td className="px-4 py-3.5 align-top tabular-nums text-gray-700 md:px-5">
                        {row.duration}
                      </td>
                      <td className="px-4 py-3.5 align-top text-gray-700 md:px-5">{row.type}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </Container>
      </Section>
    </>
  );
}

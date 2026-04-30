import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { CTASection } from "@/components/organisms/CTASection";
import { routing } from "@/i18n/routing";
import { LEGAL_PUBLIC_DEFAULTS } from "@/lib/legal/legal-public-config";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("press.title");
  const description = t("press.description");
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/press`]),
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

export default async function PressPage() {
  const t = await getTranslations("pressPage");
  const contactEmail = process.env.NEXT_PUBLIC_CONTACT_EMAIL?.trim() || LEGAL_PUBLIC_DEFAULTS.contactEmail;

  return (
    <>
      <Section className="relative overflow-hidden mesh-section-features">
        <div
          className="pointer-events-none absolute inset-0 pattern-diagonal-soft opacity-25"
          aria-hidden
        />
        <Container className="relative z-10">
          <Badge>{t("badge")}</Badge>
          <h1 className="mt-3 max-w-copy text-section-title font-bold text-gray-900">{t("title")}</h1>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-gray-600">{t("lead")}</p>

          <div className="mt-14 grid gap-12 md:grid-cols-2 md:gap-16">
            <div>
              <h2 className="text-sm font-bold uppercase tracking-[0.12em] text-gray-900">
                {t("assetsTitle")}
              </h2>
              <div className="mt-5 rounded-2xl border border-gray-200/90 bg-white/70 p-6 shadow-sm backdrop-blur-sm">
                <p className="font-semibold text-gray-900">{t("logoTitle")}</p>
                <p className="mt-2 text-sm text-gray-600">{t("logoBody")}</p>
                <a
                  href="/brand/chisto-mark.svg"
                  download
                  className="mt-4 inline-flex text-sm font-semibold text-primary underline-offset-4 hover:underline"
                >
                  {t("downloadMark")}
                </a>
              </div>
            </div>
            <div>
              <h2 className="text-sm font-bold uppercase tracking-[0.12em] text-gray-900">
                {t("inquiriesTitle")}
              </h2>
              <p className="mt-5 text-gray-600 leading-relaxed">
                {t("inquiriesLead")}{" "}
                <a
                  href={`mailto:${contactEmail}`}
                  className="font-semibold text-primary underline-offset-4 hover:underline"
                >
                  {contactEmail}
                </a>
              </p>
              <h3 className="mt-10 text-sm font-bold uppercase tracking-[0.12em] text-gray-900">
                {t("boilerplateTitle")}
              </h3>
              <p className="mt-4 rounded-xl border border-gray-100 bg-gray-50/80 p-4 text-sm leading-relaxed text-gray-700">
                {t("boilerplate")}
              </p>
            </div>
          </div>
        </Container>
      </Section>
      <CTASection />
    </>
  );
}

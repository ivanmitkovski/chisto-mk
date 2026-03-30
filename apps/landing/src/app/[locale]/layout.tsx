import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { isLocale } from "@/i18n/config";
import { getDictionary } from "@/i18n/dictionaries";

type Props = {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale: raw } = await params;
  if (!isLocale(raw)) return {};
  const d = getDictionary(raw);
  return {
    title: d.metaTitle,
    description: d.metaDescription,
    openGraph: {
      title: d.metaTitle,
      description: d.metaDescription,
      type: "website",
      locale:
        raw === "mk"
          ? "mk_MK"
          : raw === "sq"
            ? "sq_MK"
            : raw === "sr"
              ? "sr_RS"
              : raw === "rom"
                ? "en_US"
                : "en_US",
    },
    twitter: {
      card: "summary_large_image",
      title: d.metaTitle,
      description: d.metaDescription,
    },
  };
}

export default async function LocaleLayout({ children, params }: Props) {
  const { locale: raw } = await params;
  if (!isLocale(raw)) notFound();
  return children;
}

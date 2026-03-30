import { Inter } from "next/font/google";
import { NextIntlClientProvider } from "next-intl";
import { getMessages, getTranslations, setRequestLocale } from "next-intl/server";
import { notFound } from "next/navigation";
import { MotionProvider } from "@/components/layout/MotionProvider";
import { routing } from "@/i18n/routing";
import "../globals.css";

const inter = Inter({
  subsets: ["latin", "latin-ext", "cyrillic"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-inter",
  display: "swap",
});

export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!routing.locales.includes(locale as (typeof routing.locales)[number])) {
    notFound();
  }

  setRequestLocale(locale);
  const messages = await getMessages();
  const tCommon = await getTranslations({ locale, namespace: "common" });

  return (
    <html lang={locale} className={inter.variable} suppressHydrationWarning>
      <body className="relative font-sans antialiased">
        <NextIntlClientProvider messages={messages}>
          <a href="#main-content" className="skip-link">
            {tCommon("skipToContent")}
          </a>
          <MotionProvider>
            <div id="main-content" tabIndex={-1} className="outline-none">
              {children}
            </div>
          </MotionProvider>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}

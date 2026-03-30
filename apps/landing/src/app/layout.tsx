import type { Metadata, Viewport } from "next";
import { Noto_Sans } from "next/font/google";
import { headers } from "next/headers";
import { defaultLocale, isLocale } from "@/i18n/config";
import "./globals.css";

/** So `headers().get("x-locale")` runs per request (middleware sets it). */
export const dynamic = "force-dynamic";

const notoSans = Noto_Sans({
  subsets: ["latin", "latin-ext", "cyrillic", "cyrillic-ext"],
  display: "swap",
  variable: "--font-sans",
});

export const metadata: Metadata = {
  title: { default: "Chisto.mk", template: "%s" },
  description: "Граѓанска еколошка платформа за Македонија.",
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  themeColor: "#f8fafc",
  colorScheme: "light",
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const h = await headers();
  const raw = h.get("x-locale");
  const locale = raw && isLocale(raw) ? raw : defaultLocale;
  const htmlLang = locale === "sr" ? "sr-Cyrl" : locale === "rom" ? "rom" : locale;

  return (
    <html lang={htmlLang} className={notoSans.variable} suppressHydrationWarning>
      <body className={notoSans.className}>{children}</body>
    </html>
  );
}

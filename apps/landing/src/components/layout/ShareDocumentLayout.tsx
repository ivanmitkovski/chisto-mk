import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import { Inter } from "next/font/google";
import { headers } from "next/headers";
import { defaultLocale, resolveShareLocale } from "@/i18n/config";
import { getSiteUrl } from "@/lib/site-url";
import "@/app/globals.css";

const inter = Inter({
  subsets: ["latin", "latin-ext", "cyrillic"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-inter",
  display: "swap",
});

export const shareDocumentViewport: Viewport = {
  themeColor: "#2FD788",
  width: "device-width",
  initialScale: 1,
};

export const shareDocumentMetadata: Metadata = {
  metadataBase: new URL(getSiteUrl()),
};

export async function ShareDocumentLayout({ children }: { children: ReactNode }) {
  const h = await headers();
  const rawLocale = h.get("x-locale");
  const lang = resolveShareLocale(rawLocale) || defaultLocale;
  const htmlLang = lang === "sr" || lang === "rom" ? "mk" : lang;

  return (
    <html lang={htmlLang} className={inter.variable} suppressHydrationWarning>
      <body className="relative font-sans antialiased">{children}</body>
    </html>
  );
}

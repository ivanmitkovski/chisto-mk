import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { defaultLocale, isLocale, type Locale } from "@/i18n/config";

function localeFromAcceptLanguage(accept: string): Locale {
  const lower = accept.toLowerCase();
  if (lower.includes("sq")) return "sq";
  if (lower.includes("en")) return "en";
  return defaultLocale;
}

export default async function RootNotFound() {
  const h = await headers();
  const fromHeader = h.get("x-locale");
  const locale =
    fromHeader && isLocale(fromHeader) ? fromHeader : localeFromAcceptLanguage(h.get("accept-language") ?? "");
  redirect(`/${locale}`);
}

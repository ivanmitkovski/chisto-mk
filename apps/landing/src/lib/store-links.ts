import { getPublicOptionalUrl } from "@/lib/legal/legal-public-config";

/** App Store Connect listing for mk.chisto.chistoMobile (Chisto.mk). */
export const APP_STORE_APP_ID = "6771892086";

/** ID-only App Store URL — works on desktop and mobile; Apple redirects to the visitor's storefront. */
export const APP_STORE_URL_DEFAULT = `https://apps.apple.com/app/id${APP_STORE_APP_ID}`;

export function getAppStoreUrl(): string | null {
  return getPublicOptionalUrl(process.env.NEXT_PUBLIC_APP_STORE_URL) ?? APP_STORE_URL_DEFAULT;
}

export function getGooglePlayUrl(): string | null {
  return getPublicOptionalUrl(process.env.NEXT_PUBLIC_GOOGLE_PLAY_URL);
}

export function hasStoreDownloadLinks(): boolean {
  return Boolean(getAppStoreUrl() || getGooglePlayUrl());
}

export function homeDownloadSectionUrl(siteBase: string, locale: string): string {
  const normalized = siteBase.replace(/\/$/, "");
  return `${normalized}/${locale}#download`;
}

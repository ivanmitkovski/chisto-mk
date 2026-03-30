"use client";

import Image from "next/image";
import { useLocale, useTranslations } from "next-intl";
import { cn } from "@/lib/utils/cn";

/** Apple Marketing Tools badge SVGs (localized where available). */
const APPLE_BADGES: Record<string, string> = {
  en: "/badges/app-store-en.svg",
  mk: "/badges/app-store-mk.svg",
  sq: "/badges/app-store-sq.svg",
};

/** Google Play badge PNGs (per-language artwork from play.google.com/intl/...). */
const GOOGLE_BADGES: Record<string, string> = {
  en: "/badges/google-play-en.png",
  mk: "/badges/google-play-mk.png",
  sq: "/badges/google-play-sq.png",
};

interface AppStoreButtonProps {
  store: "apple" | "google";
  className?: string;
}

export function AppStoreButton({ store, className }: AppStoreButtonProps) {
  const locale = useLocale();
  const t = useTranslations("appStore");
  const isApple = store === "apple";
  const badgeSrc = isApple
    ? (APPLE_BADGES[locale] ?? APPLE_BADGES.en)
    : (GOOGLE_BADGES[locale] ?? GOOGLE_BADGES.en);

  return (
    <a
      href="#"
      className={cn(
        "inline-flex items-center leading-none transition-opacity hover:opacity-[0.92]",
        "focus-visible:rounded-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
        className,
      )}
      aria-label={isApple ? t("appleAria") : t("googleAria")}
    >
      <Image
        src={badgeSrc}
        alt=""
        width={isApple ? 120 : 646}
        height={isApple ? 40 : 250}
        className={cn(
          "w-auto",
          isApple ? "h-10 md:h-11" : "h-[58px] md:h-[64px]",
        )}
        unoptimized={isApple}
      />
    </a>
  );
}

"use client";

import type { CSSProperties } from "react";
import Image from "next/image";
import { useLocale, useTranslations } from "next-intl";
import { cn } from "@/lib/utils/cn";
import {
  APPLE_BADGE_HEIGHT_PX,
  APPLE_BADGE_WIDTH_PX,
  GOOGLE_BADGE_BLEED_X_RATIO,
  GOOGLE_BADGE_WIDTH_PX,
  STORE_BADGE_ROW_HEIGHT_MD_PX,
  STORE_BADGE_ROW_HEIGHT_PX,
  googleBadgeVisibleWidthPx,
} from "@/lib/store-badges";
import { getAppStoreUrl, getGooglePlayUrl } from "@/lib/store-links";
import { trackMarketingEvent } from "@/lib/analytics/track-marketing";

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
  analyticsSource?: string;
}

export function AppStoreButton({ store, className, analyticsSource }: AppStoreButtonProps) {
  const locale = useLocale();
  const t = useTranslations("appStore");
  const isApple = store === "apple";
  const href = isApple ? getAppStoreUrl() : getGooglePlayUrl();
  const badgeSrc = isApple
    ? (APPLE_BADGES[locale] ?? APPLE_BADGES.en)
    : (GOOGLE_BADGES[locale] ?? GOOGLE_BADGES.en);
  const ariaLabel = isApple ? t("appleAria") : t("googleAria");

  if (!href) {
    return null;
  }

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      onClick={() => {
        const source =
          analyticsSource ?? (isApple ? "app_store_badge" : "google_play_badge");
        trackMarketingEvent(isApple ? "app_store_open" : "google_play_open", {
          source,
        });
      }}
      className={cn(
        "inline-flex shrink-0 items-center justify-start",
        "h-[58px] md:h-16",
        !isApple &&
          "w-[var(--google-badge-visible-w)] overflow-hidden md:w-[var(--google-badge-visible-w-md)]",
        "leading-none transition-opacity hover:opacity-[0.92]",
        "focus-visible:rounded-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
        className,
      )}
      style={
        !isApple
          ? ({
              "--google-badge-visible-w": `${googleBadgeVisibleWidthPx(STORE_BADGE_ROW_HEIGHT_PX)}px`,
              "--google-badge-visible-w-md": `${googleBadgeVisibleWidthPx(STORE_BADGE_ROW_HEIGHT_MD_PX)}px`,
            } as CSSProperties)
          : undefined
      }
      aria-label={ariaLabel}
    >
      <Image
        src={badgeSrc}
        alt=""
        width={isApple ? APPLE_BADGE_WIDTH_PX : GOOGLE_BADGE_WIDTH_PX}
        height={isApple ? APPLE_BADGE_HEIGHT_PX : STORE_BADGE_ROW_HEIGHT_PX}
        className={cn(
          "w-auto",
          isApple ? "h-10 md:h-11" : "h-[58px] md:h-16 max-w-none",
        )}
        style={
          !isApple
            ? { transform: `translateX(calc(-100% * ${GOOGLE_BADGE_BLEED_X_RATIO}))` }
            : undefined
        }
        unoptimized
      />
    </a>
  );
}

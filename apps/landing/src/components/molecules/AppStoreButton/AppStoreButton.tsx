"use client";

import { useState } from "react";
import Image from "next/image";
import { useLocale, useTranslations } from "next-intl";
import { cn } from "@/lib/utils/cn";
import { getPublicOptionalUrl } from "@/lib/legal/legal-public-config";

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
  const [showComingSoon, setShowComingSoon] = useState(false);
  const isApple = store === "apple";
  const href = isApple
    ? getPublicOptionalUrl(process.env.NEXT_PUBLIC_APP_STORE_URL)
    : getPublicOptionalUrl(process.env.NEXT_PUBLIC_GOOGLE_PLAY_URL);
  const badgeSrc = isApple
    ? (APPLE_BADGES[locale] ?? APPLE_BADGES.en)
    : (GOOGLE_BADGES[locale] ?? GOOGLE_BADGES.en);
  const ariaLabel = isApple ? t("appleAria") : t("googleAria");

  const badgeImage = (
    <Image
      src={badgeSrc}
      alt=""
      width={isApple ? 120 : 646}
      height={isApple ? 40 : 250}
      className={cn("w-auto", isApple ? "h-10 md:h-11" : "h-[58px] md:h-[64px]")}
      unoptimized={isApple}
    />
  );

  if (href) {
    return (
      <a
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        className={cn(
          "inline-flex items-center leading-none transition-opacity hover:opacity-[0.92]",
          "focus-visible:rounded-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
          className,
        )}
        aria-label={ariaLabel}
      >
        {badgeImage}
      </a>
    );
  }

  return (
    <div className={cn("relative inline-flex flex-col items-center gap-2", className)}>
      <button
        type="button"
        aria-disabled="true"
        aria-label={`${ariaLabel} — ${t("comingSoon")}`}
        aria-describedby={showComingSoon ? `coming-soon-${store}` : undefined}
        onClick={() => setShowComingSoon(true)}
        className={cn(
          "inline-flex cursor-not-allowed items-center leading-none opacity-90 transition-opacity",
          "focus-visible:rounded-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
        )}
      >
        {badgeImage}
      </button>
      {showComingSoon && (
        <span
          id={`coming-soon-${store}`}
          role="status"
          className="rounded-full bg-gray-900 px-3 py-1 text-xs font-medium text-white shadow-md"
        >
          {t("comingSoon")}
        </span>
      )}
    </div>
  );
}

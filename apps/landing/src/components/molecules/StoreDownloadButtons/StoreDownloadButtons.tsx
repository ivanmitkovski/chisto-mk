"use client";

import { AppStoreButton } from "@/components/molecules/AppStoreButton";
import { hasStoreDownloadLinks } from "@/lib/store-links";
import type { StoreBadgeAlign } from "@/lib/store-badges";
import { cn } from "@/lib/utils/cn";

interface StoreDownloadButtonsProps {
  className?: string;
  analyticsSource?: string;
  /** Horizontal alignment of the badge row (default: center). */
  align?: StoreBadgeAlign;
}

export function StoreDownloadButtons({
  className,
  analyticsSource,
  align = "center",
}: StoreDownloadButtonsProps) {
  if (!hasStoreDownloadLinks()) {
    return null;
  }

  return (
    <div
      className={cn(
        "flex flex-row flex-nowrap items-center gap-3 sm:gap-4",
        align === "center" ? "justify-center" : "justify-start",
        className,
      )}
      role="group"
      aria-label="Download Chisto.mk"
    >
      <AppStoreButton store="apple" analyticsSource={analyticsSource ?? "app_store_badge"} />
      <AppStoreButton store="google" analyticsSource={analyticsSource ?? "google_play_badge"} />
    </div>
  );
}

export { hasStoreDownloadLinks };

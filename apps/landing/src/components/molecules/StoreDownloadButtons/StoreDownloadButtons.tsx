"use client";

import { AppStoreButton } from "@/components/molecules/AppStoreButton";
import { hasStoreDownloadLinks } from "@/lib/store-links";
import { cn } from "@/lib/utils/cn";

interface StoreDownloadButtonsProps {
  className?: string;
  analyticsSource?: string;
}

export function StoreDownloadButtons({ className, analyticsSource }: StoreDownloadButtonsProps) {
  if (!hasStoreDownloadLinks()) {
    return null;
  }

  return (
    <div className={cn("flex flex-wrap items-center gap-3 sm:gap-4", className)}>
      <AppStoreButton store="apple" analyticsSource={analyticsSource ?? "app_store_badge"} />
      <AppStoreButton store="google" analyticsSource={analyticsSource ?? "google_play_badge"} />
    </div>
  );
}

export { hasStoreDownloadLinks };

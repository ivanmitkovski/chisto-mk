"use client";

import { AppStoreButton } from "@/components/molecules/AppStoreButton";
import { getPublicOptionalUrl } from "@/lib/legal/legal-public-config";
import { cn } from "@/lib/utils/cn";

export function hasStoreDownloadLinks(): boolean {
  return Boolean(
    getPublicOptionalUrl(process.env.NEXT_PUBLIC_APP_STORE_URL) ||
      getPublicOptionalUrl(process.env.NEXT_PUBLIC_GOOGLE_PLAY_URL),
  );
}

interface StoreDownloadButtonsProps {
  className?: string;
}

export function StoreDownloadButtons({ className }: StoreDownloadButtonsProps) {
  if (!hasStoreDownloadLinks()) {
    return null;
  }

  return (
    <div className={cn("flex flex-wrap items-center gap-3 sm:gap-4", className)}>
      <AppStoreButton store="apple" />
      <AppStoreButton store="google" />
    </div>
  );
}

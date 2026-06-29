"use client";

import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import { buttonVariants } from "@/components/atoms/Button/Button";
import { trackMarketingEvent } from "@/lib/analytics/track-marketing";
import { useDownloadNavigation } from "@/lib/navigation/download-navigation";
import { cn } from "@/lib/utils/cn";

type DownloadCTAProps = {
  className?: string;
  size?: "sm" | "md";
  variant?: "primary" | "secondary";
  analyticsSource?: string;
  /** Runs before default download navigation (e.g. close mobile drawer). */
  onNavigate?: () => void;
};

export function DownloadCTA({
  className,
  size = "sm",
  variant = "primary",
  analyticsSource = "download_cta",
  onNavigate,
}: DownloadCTAProps) {
  const t = useTranslations("common");
  const { downloadHref, handleDownloadLinkClick } = useDownloadNavigation();

  return (
    <Link
      href={downloadHref}
      onClick={(e) => {
        onNavigate?.();
        trackMarketingEvent("download_cta_click", { source: analyticsSource });
        handleDownloadLinkClick(e);
      }}
      className={cn(buttonVariants({ variant, size }), className)}
    >
      {t("download")}
    </Link>
  );
}

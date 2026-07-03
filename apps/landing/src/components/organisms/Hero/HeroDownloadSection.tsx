"use client";

import { useTranslations } from "next-intl";
import { StoreDownloadButtons } from "@/components/molecules/StoreDownloadButtons";
import { DOWNLOAD_SECTION_ID } from "@/lib/utils/smooth-scroll";

export function HeroDownloadSection() {
  const t = useTranslations("hero");

  return (
    <section
      id={DOWNLOAD_SECTION_ID}
      aria-label={t("downloadRegionLabel")}
      className="mx-auto flex max-w-lg flex-col items-center rounded-2xl px-3 py-2 sm:px-4"
    >
      <StoreDownloadButtons align="center" analyticsSource="hero" />
    </section>
  );
}

"use client";

import { useTranslations } from "next-intl";
import type { AboutCreator } from "./about-page.types";
import { AboutHero } from "./AboutHero";
import { AboutTeam } from "./AboutTeam";

export function AboutPage() {
  const t = useTranslations("aboutPage");
  const creatorsRaw = t.raw("creators") as AboutCreator[] | undefined;
  const creators = Array.isArray(creatorsRaw) ? creatorsRaw : [];

  return (
    <>
      <AboutHero badge={t("badge")} title={t("title")} subtitle={t("subtitle")} />
      <AboutTeam
        sectionTitle={t("creatorsSectionTitle")}
        photoPlaceholder={t("creatorsPhotoPlaceholder")}
        carouselPrevLabel={t("teamCarouselPrev")}
        carouselNextLabel={t("teamCarouselNext")}
        creators={creators}
      />
    </>
  );
}

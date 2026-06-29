"use client";

import { useEffect } from "react";
import { motion } from "framer-motion";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { hasStoreDownloadLinks } from "@/components/molecules/StoreDownloadButtons";
import { MarketingPhoneRow } from "@/components/molecules/MarketingPhoneRow";
import { fadeInUp, staggerContainer } from "@/lib/animations/variants";
import { DOWNLOAD_SECTION_ID } from "@/lib/utils/smooth-scroll";
import { scrollToDownloadFromHashNavigation } from "@/lib/navigation/download-navigation";
import { HeroAtmosphere, HeroWaveFooter } from "./HeroAtmosphere";
import { HeroDownloadSection } from "./HeroDownloadSection";
import { HeroPhoneSwipeDeck } from "./HeroPhoneSwipeDeck";

export function Hero() {
  const t = useTranslations("hero");

  useEffect(() => {
    const syncHash = () => {
      if (window.location.hash === `#${DOWNLOAD_SECTION_ID}`) {
        scrollToDownloadFromHashNavigation();
      }
    };

    syncHash();
    window.addEventListener("hashchange", syncHash);
    return () => window.removeEventListener("hashchange", syncHash);
  }, []);

  return (
    <Section className="relative overflow-x-clip mesh-hero !pb-20 !pt-7 md:!pb-28 md:!pt-12 lg:!pb-32 lg:!pt-14">
      <HeroAtmosphere />

      <Container className="relative z-20">
        <motion.div
          className="mx-auto text-center"
          variants={staggerContainer}
          initial="hidden"
          animate="visible"
        >
          <motion.h1
            className="text-hero font-bold tracking-tight text-gray-900 text-balance"
            variants={fadeInUp}
          >
            {t("title")}
          </motion.h1>

          <motion.p
            className="mx-auto mt-6 max-w-2xl text-balance text-base font-semibold leading-relaxed text-gray-800 [text-shadow:0_1px_14px_rgba(255,255,255,0.85),0_0_1px_rgba(255,255,255,0.6)] md:text-lg md:leading-relaxed"
            variants={fadeInUp}
          >
            {t("subtitle")}
          </motion.p>

          {hasStoreDownloadLinks() ? (
            <motion.div variants={fadeInUp} className="mt-10">
              <HeroDownloadSection />
            </motion.div>
          ) : null}
        </motion.div>

        <div className="relative mx-auto mt-12 max-w-5xl overflow-visible md:mt-16">
          <div
            className="absolute inset-x-[6%] -bottom-2 top-[38%] hidden rounded-[2.75rem] bg-gradient-to-b from-white/25 via-gray-100/20 to-gray-200/15 shadow-[var(--shadow-soft)] ring-1 ring-black/[0.025] md:block md:inset-x-[10%] md:top-[35%] md:rounded-[3rem]"
            aria-hidden
          />
          <div className="relative z-10 flex items-end justify-center overflow-visible pb-2">
            <div className="flex w-full justify-center overflow-visible md:hidden">
              <HeroPhoneSwipeDeck />
            </div>

            <MarketingPhoneRow className="hidden md:flex" priorityIndex={1} />
          </div>
        </div>
      </Container>

      <HeroWaveFooter />
    </Section>
  );
}

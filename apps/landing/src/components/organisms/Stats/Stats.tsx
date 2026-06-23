"use client";

import { motion } from "framer-motion";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { StatCard } from "@/components/molecules/StatCard";
import { getPublicStats } from "@/lib/stats/public-stats";
import { staggerContainer, fadeInUp, fadeInUpTight, viewOnce } from "@/lib/animations/variants";
import { splitParagraphs } from "@/lib/utils/split-paragraphs";

type StatsProps = {
  statsIntro?: { title: string; subtitle: string };
};

export function Stats({ statsIntro }: StatsProps) {
  const t = useTranslations("stats");
  const { items, asOf } = getPublicStats();

  return (
    <div className="mesh-section-stats relative overflow-hidden border-y border-gray-200/70 py-[var(--section-y-tight)] md:py-[var(--section-y-lg)]">
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-r from-primary/[0.04] via-transparent to-primary/[0.04]" aria-hidden />
      <div
        className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-[0.22]"
        aria-hidden
      />
      <Container className="relative z-10">
        {statsIntro ? (
          <motion.div
            className="mx-auto mb-10 max-w-3xl text-center md:mb-14"
            variants={staggerContainer}
            initial="hidden"
            whileInView="visible"
            viewport={viewOnce}
          >
            <motion.h2 className="text-about-section-title text-balance" variants={fadeInUp}>
              {statsIntro.title}
            </motion.h2>
            <motion.div
              variants={fadeInUp}
              className="mx-auto mt-4 max-w-2xl space-y-4 text-about-lead md:mt-5"
            >
              {splitParagraphs(statsIntro.subtitle).map((para, i) => (
                <p key={i}>{para}</p>
              ))}
            </motion.div>
          </motion.div>
        ) : null}
        <motion.p
          className="mb-8 text-center text-xs font-medium uppercase tracking-wider text-gray-500"
          variants={fadeInUpTight}
          initial="hidden"
          whileInView="visible"
          viewport={viewOnce}
        >
          {t("asOf", { date: asOf })}
        </motion.p>
        <motion.div
          className="mx-auto grid max-w-6xl grid-cols-1 gap-5 sm:grid-cols-2 sm:gap-6 lg:grid-cols-4 lg:gap-5"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={viewOnce}
        >
          {items.map((stat) => (
            <motion.div key={stat.labelKey} variants={fadeInUpTight} className="min-w-0">
              <StatCard number={stat.number} label={t(`labels.${stat.labelKey}`)} />
            </motion.div>
          ))}
        </motion.div>
      </Container>
    </div>
  );
}

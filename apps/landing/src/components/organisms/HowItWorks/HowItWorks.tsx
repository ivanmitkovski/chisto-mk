"use client";

import { motion } from "framer-motion";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { StepCard } from "@/components/molecules/StepCard";
import {
  fadeInUp,
  staggerContainer,
  staggerContainerLoose,
  lineReveal,
  viewOnce,
} from "@/lib/animations/variants";

type Step = { title: string; description: string };

export function HowItWorks() {
  const t = useTranslations("howItWorks");
  const steps = t.raw("steps") as Step[];

  return (
    <Section className="relative overflow-hidden mesh-section-how">
      <div
        className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-[0.35] [mask-image:linear-gradient(to_bottom,transparent,black_12%,black_88%,transparent)] [-webkit-mask-image:linear-gradient(to_bottom,transparent,black_12%,black_88%,transparent)]"
        aria-hidden
      />
      <div className="pointer-events-none absolute inset-0 pattern-diagonal-soft opacity-40" aria-hidden />
      <div
        className="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-primary/15 to-transparent"
        aria-hidden
      />
      <Container className="relative z-10">
        <motion.div
          className="mx-auto max-w-2xl text-center"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={viewOnce}
        >
          <motion.h2 className="text-section-title font-bold text-gray-900" variants={fadeInUp}>
            {t("title")}
          </motion.h2>
          <motion.p
            className="mt-4 text-base leading-relaxed text-gray-600 md:text-lg md:leading-relaxed"
            variants={fadeInUp}
          >
            {t("subtitle")}
          </motion.p>
        </motion.div>

        <motion.div
          className="relative mt-14 grid grid-cols-1 gap-14 md:mt-20 md:grid-cols-3 md:gap-6 lg:gap-10"
          variants={staggerContainerLoose}
          initial="hidden"
          whileInView="visible"
          viewport={viewOnce}
        >
          <div
            className="pointer-events-none absolute inset-x-[-12%] bottom-0 top-4 z-0 grid-lines-tight opacity-[0.26] [mask-image:linear-gradient(to_bottom,transparent,black_12%,black_88%,transparent)] [-webkit-mask-image:linear-gradient(to_bottom,transparent,black_12%,black_88%,transparent)] md:inset-x-[-6%]"
            aria-hidden
          />
          <motion.div
            variants={lineReveal}
            className="pointer-events-none absolute left-[17%] right-[17%] top-8 z-0 hidden h-0 origin-center border-t-2 border-dashed border-primary/35 md:block"
            style={{ transformOrigin: "50% 50%" }}
            aria-hidden
          />

          {steps.map((step, index) => (
            <StepCard
              key={index}
              number={index + 1}
              title={step.title}
              description={step.description}
            />
          ))}
        </motion.div>
      </Container>
    </Section>
  );
}

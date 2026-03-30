"use client";

import { motion } from "framer-motion";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { Badge } from "@/components/atoms/Badge";
import { FAQItem } from "@/components/molecules/FAQItem";
import {
  fadeInUp,
  fadeInUpTight,
  staggerContainer,
  staggerContainerLoose,
  viewOnce,
} from "@/lib/animations/variants";

type FaqEntry = { title: string; content: string; variant: "green" | "white" };

export function FAQ() {
  const t = useTranslations("faq");
  const items = t.raw("items") as FaqEntry[];

  return (
    <Section className="relative overflow-hidden mesh-section-faq">
      <div className="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-gray-200 to-transparent" aria-hidden />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-gray-200/90 to-transparent" aria-hidden />
      <div
        className="pointer-events-none absolute inset-0 pattern-diagonal-soft opacity-[0.35] [mask-image:linear-gradient(to_bottom,transparent,black_15%,black_85%,transparent)] [-webkit-mask-image:linear-gradient(to_bottom,transparent,black_15%,black_85%,transparent)]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_65%_50%_at_100%_0%,rgba(0,217,142,0.07),transparent_52%)]"
        aria-hidden
      />
      <Container className="relative z-10">
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={viewOnce}
          variants={staggerContainer}
        >
          <motion.div variants={fadeInUpTight}>
            <Badge>{t("badge")}</Badge>
          </motion.div>
          <motion.h2
            className="mt-3 text-section-title font-bold text-gray-900"
            variants={fadeInUpTight}
          >
            {t("title")}
          </motion.h2>

          <motion.div
            className="mt-12 grid auto-rows-fr gap-5 sm:gap-6 md:grid-cols-2"
            variants={staggerContainerLoose}
          >
            {items.map((item, i) => (
              <motion.div key={i} variants={fadeInUp} className="flex h-full">
                <FAQItem title={item.title} content={item.content} variant={item.variant} />
              </motion.div>
            ))}
          </motion.div>
        </motion.div>
      </Container>
    </Section>
  );
}

"use client";

import { motion } from "framer-motion";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { staggerContainer, fadeInUp, viewOnce } from "@/lib/animations/variants";
import { splitParagraphs } from "@/lib/utils/split-paragraphs";

type AboutHeroProps = {
  badge: string;
  title: string;
  subtitle: string;
};

export function AboutHero({ badge, title, subtitle }: AboutHeroProps) {
  const subtitleParas = splitParagraphs(subtitle).filter((p) => p.trim().length > 0);

  return (
    <Section className="relative overflow-hidden mesh-section-about-hero">
      <div className="pointer-events-none absolute inset-0 pattern-dots-soft opacity-[0.07]" aria-hidden />
      <Container className="relative z-10">
        <motion.div
          className="mx-auto max-w-3xl text-center lg:mx-0 lg:text-left"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={viewOnce}
        >
          <motion.div variants={fadeInUp} className="flex justify-center lg:justify-start">
            <Badge variant="about">{badge}</Badge>
          </motion.div>
          <motion.h1
            className="text-about-hero mt-5 text-balance"
            variants={fadeInUp}
          >
            {title}
          </motion.h1>
          {subtitleParas.length > 0 ? (
            <motion.div
              className="mx-auto mt-4 max-w-2xl space-y-2 text-pretty text-about-prose lg:mx-0"
              variants={fadeInUp}
            >
              {subtitleParas.map((para, i) => (
                <p key={i}>{para}</p>
              ))}
            </motion.div>
          ) : null}
        </motion.div>
      </Container>
    </Section>
  );
}

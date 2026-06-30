"use client";

import { motion, useReducedMotion } from "framer-motion";
import { Camera, MapPin, Users } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { Badge } from "@/components/atoms/Badge";
import { FeatureCard } from "@/components/molecules/FeatureCard";
import { PhoneMockup } from "@/components/molecules/PhoneMockup";
import { PhoneScreenshot } from "@/components/molecules/PhoneScreenshot";
import {
  slideInLeft,
  slideInRight,
  staggerContainer,
  viewOnce,
  easeOutExpo,
} from "@/lib/animations/variants";

type FeatureItem = { title: string; description: string };

const FEATURE_ICONS: LucideIcon[] = [MapPin, Camera, Users];

function BlobBackdrop() {
  const reduceMotion = useReducedMotion();

  return (
    <>
      <div
        className="absolute -inset-8 -z-20 rounded-[3rem] bg-gradient-to-tr from-sky-100/40 via-transparent to-primary/10 blur-2xl"
        aria-hidden
      />
      {reduceMotion ? (
        <div
          className="absolute inset-0 -z-10 scale-[1.36] rounded-full bg-primary/24 blur-3xl"
          aria-hidden
        />
      ) : (
        <motion.div
          className="absolute inset-0 -z-10 scale-[1.32] rounded-full bg-primary/22 blur-3xl"
          aria-hidden
          animate={{
            scale: [1.32, 1.44, 1.32],
            opacity: [0.2, 0.34, 0.2],
          }}
          transition={{ duration: 12, repeat: Infinity, ease: "easeInOut" }}
        />
      )}
    </>
  );
}

export function Features() {
  const t = useTranslations("features");
  const items = t.raw("items") as FeatureItem[];

  return (
    <Section className="relative overflow-hidden mesh-section-features" defer>
      <div
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_85%_55%_at_50%_-8%,rgba(0,217,142,0.08),transparent_58%)]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 pattern-dots-large opacity-[0.4] [mask-image:linear-gradient(to_bottom,transparent,black_10%,black_90%,transparent)] [-webkit-mask-image:linear-gradient(to_bottom,transparent,black_10%,black_90%,transparent)]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 grid-lines-fade opacity-[0.34]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-amber-200/40 to-transparent"
        aria-hidden
      />

      <Container className="relative z-10 flex flex-col gap-24 md:gap-28">
        <motion.div
          className="grid items-center gap-12 md:grid-cols-2 md:gap-x-16 md:gap-y-0"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={viewOnce}
        >
          <motion.div variants={slideInLeft} className="relative mx-auto w-64 md:mx-0 lg:w-72">
            <BlobBackdrop />
            <PhoneMockup>
              <PhoneScreenshot screenshotId="map" />
            </PhoneMockup>
          </motion.div>

          <motion.div variants={slideInRight} className="md:pl-2">
            <Badge>{t("badge")}</Badge>
            <h2 className="mt-3 text-section-title font-bold text-gray-900">{t("block1Title")}</h2>
            <div className="mt-8 space-y-2 md:space-y-3">
              {items.map((f, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 18 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={viewOnce}
                  transition={{
                    delay: 0.08 + i * 0.11,
                    duration: 0.6,
                    ease: easeOutExpo,
                  }}
                >
                  <FeatureCard
                    title={f.title}
                    description={f.description}
                    icon={FEATURE_ICONS[i] ?? MapPin}
                  />
                </motion.div>
              ))}
            </div>
          </motion.div>
        </motion.div>

        <motion.div
          className="grid items-center gap-12 md:grid-cols-2 md:gap-x-16 md:gap-y-0"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={viewOnce}
        >
          <motion.div variants={slideInLeft} className="order-2 max-w-copy md:order-1 md:pr-4">
            <Badge>{t("badge")}</Badge>
            <h2 className="mt-3 text-section-title font-bold text-gray-900">{t("block2Title")}</h2>
            <p className="mt-4 text-base leading-relaxed text-gray-600 md:text-lg">{t("block2Body")}</p>
          </motion.div>

          <motion.div
            variants={slideInRight}
            className="relative order-1 mx-auto w-64 md:order-2 md:mx-0 md:justify-self-end lg:w-72"
          >
            <BlobBackdrop />
            <PhoneMockup>
              <PhoneScreenshot screenshotId="events" />
            </PhoneMockup>
          </motion.div>
        </motion.div>
      </Container>
    </Section>
  );
}

"use client";

import { motion } from "framer-motion";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { Badge } from "@/components/atoms/Badge";
import { FeatureCard } from "@/components/molecules/FeatureCard";
import { PhoneMockup } from "@/components/molecules/PhoneMockup";
import {
  slideInLeft,
  slideInRight,
  staggerContainer,
  viewOnce,
  easeOutExpo,
} from "@/lib/animations/variants";

type FeatureItem = { title: string; description: string };

function FeaturePhone({
  urgent,
  pollutionSites,
  takeAction,
}: {
  urgent: string;
  pollutionSites: string;
  takeAction: string;
}) {
  return (
    <div className="flex aspect-[9/19.5] flex-col rounded-3xl bg-white p-4">
      <div className="mb-2 flex items-center justify-between">
        <div className="h-3 w-20 rounded-md bg-gray-200" />
        <div className="h-6 min-w-14 rounded-full bg-red-50 px-2 text-center text-[10px] font-medium leading-6 text-red-600 ring-1 ring-red-100">
          {urgent}
        </div>
      </div>
      <div className="mb-3 text-sm font-semibold text-gray-800">{pollutionSites}</div>
      <div className="flex-1 space-y-3">
        <div className="rounded-xl bg-gray-50/90 p-3 shadow-inner ring-1 ring-gray-100">
          <div className="mb-1 h-3 w-24 rounded bg-gray-200" />
          <div className="h-2 w-full rounded bg-gray-100" />
        </div>
        <div className="rounded-xl bg-gray-50/90 p-3 shadow-inner ring-1 ring-gray-100">
          <div className="mb-1 h-3 w-20 rounded bg-gray-200" />
          <div className="h-2 w-3/4 rounded bg-gray-100" />
        </div>
      </div>
      <div className="mt-3 rounded-xl bg-primary py-2.5 text-center text-xs font-semibold text-white shadow-[0_8px_24px_rgba(0,217,142,0.35)]">
        {takeAction}
      </div>
    </div>
  );
}

function ReportPhone({ before }: { before: string }) {
  return (
    <div className="flex aspect-[9/19.5] flex-col rounded-3xl bg-white p-4">
      <div className="mb-3 flex items-center gap-2">
        <div className="h-3 w-12 rounded-md bg-gray-200" />
        <div className="h-5 min-w-12 rounded-full bg-emerald-50 px-2 text-center text-[10px] font-medium leading-5 text-emerald-700 ring-1 ring-emerald-100">
          {before}
        </div>
      </div>
      <div className="flex-1 space-y-3">
        <div className="aspect-video w-full rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 shadow-inner ring-1 ring-amber-100/80" />
        <div className="h-3 w-3/4 rounded-md bg-gray-200" />
        <div className="h-2 w-full rounded bg-gray-100" />
        <div className="h-2 w-5/6 rounded bg-gray-100" />
      </div>
      <div className="mt-3 flex items-center gap-2">
        <div className="h-8 w-8 rounded-full bg-gray-100 ring-2 ring-gray-200/80" />
        <div className="h-3 w-20 rounded-md bg-gray-200" />
      </div>
    </div>
  );
}

function BlobBackdrop() {
  return (
    <>
      <div
        className="absolute -inset-8 -z-20 rounded-[3rem] bg-gradient-to-tr from-sky-100/40 via-transparent to-primary/10 blur-2xl"
        aria-hidden
      />
      <motion.div
        className="absolute inset-0 -z-10 scale-[1.32] rounded-full bg-primary/22 blur-3xl"
        aria-hidden
        animate={{
          scale: [1.32, 1.44, 1.32],
          opacity: [0.2, 0.34, 0.2],
        }}
        transition={{ duration: 12, repeat: Infinity, ease: "easeInOut" }}
      />
    </>
  );
}

export function Features() {
  const t = useTranslations("features");
  const items = t.raw("items") as FeatureItem[];

  const mock = {
    urgent: t("mock.urgent"),
    pollutionSites: t("mock.pollutionSites"),
    takeAction: t("mock.takeAction"),
    before: t("mock.before"),
  };

  return (
    <Section className="relative overflow-hidden mesh-section-features">
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
              <FeaturePhone
                urgent={mock.urgent}
                pollutionSites={mock.pollutionSites}
                takeAction={mock.takeAction}
              />
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
                  <FeatureCard title={f.title} description={f.description} />
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
              <ReportPhone before={mock.before} />
            </PhoneMockup>
          </motion.div>
        </motion.div>
      </Container>
    </Section>
  );
}

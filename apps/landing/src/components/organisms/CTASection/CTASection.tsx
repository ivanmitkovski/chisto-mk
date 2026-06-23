"use client";

import { motion } from "framer-motion";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { StoreDownloadButtons, hasStoreDownloadLinks } from "@/components/molecules/StoreDownloadButtons";
import { FloatingPhone } from "@/components/molecules/FloatingPhone";
import { PhoneMockup } from "@/components/molecules/PhoneMockup";
import { PhoneScreen } from "@/components/molecules/PhoneDemoScreens";
import { MARKETING_PHONE_SCREENSHOTS } from "@/lib/app-screenshots";
import { fadeInUp, staggerContainer, viewOnce } from "@/lib/animations/variants";

export function CTASection() {
  const t = useTranslations("cta");

  return (
    <div className="relative overflow-x-clip bg-black py-[var(--section-y-lg)] md:py-28 lg:py-32">
      <div className="pointer-events-none absolute inset-0 mesh-cta opacity-95" aria-hidden />
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-black via-black to-zinc-950/95" aria-hidden />
      <div
        className="pointer-events-none absolute inset-0 mix-blend-screen opacity-90 [background-image:radial-gradient(ellipse_90%_55%_at_50%_0%,rgba(255,255,255,0.14),transparent_55%),radial-gradient(ellipse_55%_45%_at_0%_100%,rgba(0,217,142,0.2),transparent_58%)]"
        aria-hidden
      />
      <div className="pointer-events-none absolute inset-0 noise-overlay-dark opacity-70" aria-hidden />
      <div
        className="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-primary/45 to-transparent"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-white/10 to-transparent"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute -right-24 top-1/2 h-[30rem] w-[30rem] -translate-y-1/2 rounded-full bg-primary/14 blur-[110px]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute bottom-0 left-[12%] h-72 w-72 rounded-full bg-primary/10 blur-3xl"
        aria-hidden
      />

      <Container className="relative z-10">
        <div className="grid items-center gap-14 md:grid-cols-2 md:gap-16 lg:gap-20">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={viewOnce}
            variants={staggerContainer}
            className="max-w-xl"
          >
            <motion.h2
              className="text-[clamp(2rem,4vw+1rem,3.25rem)] font-bold leading-[1.08] tracking-tight text-white"
              variants={fadeInUp}
            >
              {t("title")}
            </motion.h2>
            <motion.p
              className="mt-5 max-w-md text-base leading-relaxed text-gray-300/95 md:text-lg md:text-gray-200/90"
              variants={fadeInUp}
            >
              {t("subtitle")}
            </motion.p>
            {hasStoreDownloadLinks() ? (
              <motion.div
                className="mt-10 flex flex-wrap items-center gap-3 sm:gap-4"
                variants={fadeInUp}
              >
                <StoreDownloadButtons />
              </motion.div>
            ) : null}
          </motion.div>

          <div className="relative flex min-h-[14rem] items-end justify-center overflow-visible md:hidden">
            <FloatingPhone className="w-[11rem]" delay={0}>
              <PhoneMockup className="shadow-[var(--shadow-phone-lg)]">
                <PhoneScreen variant="feed" priority />
              </PhoneMockup>
            </FloatingPhone>
          </div>

          <div className="relative hidden min-h-[20rem] overflow-visible md:flex md:items-end md:justify-center md:gap-2 md:pb-4 lg:gap-3">
            {MARKETING_PHONE_SCREENSHOTS.map((screenshotId, index) => (
              <FloatingPhone
                key={screenshotId}
                className={index === 1 ? "relative z-10 w-[11rem] lg:w-44" : "w-40"}
                delay={index * 0.12}
              >
                <PhoneMockup
                  {...(index === 1 ? { className: "shadow-[var(--shadow-phone-lg)]" } : {})}
                >
                  <PhoneScreen
                    variant={screenshotId}
                    {...(index === 1 ? { priority: true } : {})}
                  />
                </PhoneMockup>
              </FloatingPhone>
            ))}
          </div>
        </div>
      </Container>
    </div>
  );
}

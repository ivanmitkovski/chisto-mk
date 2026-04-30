"use client";

import { motion } from "framer-motion";
import { useTranslations } from "next-intl";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { AppStoreButton } from "@/components/molecules/AppStoreButton";
import { PhoneMockup } from "@/components/molecules/PhoneMockup";
import { PhoneScreen } from "@/components/molecules/PhoneDemoScreens";
import { FloatingPhone } from "@/components/molecules/FloatingPhone";
import { fadeInUp, staggerContainer } from "@/lib/animations/variants";
import { HeroPhoneSwipeDeck } from "./HeroPhoneSwipeDeck";

export function Hero() {
  const t = useTranslations("hero");

  return (
    <Section className="relative overflow-hidden mesh-hero !pb-20 !pt-7 md:!pb-28 md:!pt-12 lg:!pb-32 lg:!pt-14">
      {/* Under the grid: soft brand blooms (multiply keeps it grounded) */}
      <div
        className="pointer-events-none absolute inset-0 z-0 opacity-[0.55] mix-blend-multiply"
        aria-hidden
      >
        <div className="absolute -left-[8%] top-[-12%] h-[min(78vw,38rem)] w-[min(78vw,38rem)] rounded-full bg-[radial-gradient(circle_at_40%_40%,rgba(0,217,142,0.2)_0%,rgba(0,217,142,0.06)_38%,transparent_68%)] blur-3xl md:opacity-90" />
        <div className="absolute -right-[6%] top-[0%] h-[min(70vw,34rem)] w-[min(70vw,34rem)] rounded-full bg-[radial-gradient(circle_at_55%_45%,rgba(125,211,252,0.18)_0%,rgba(125,211,252,0.05)_40%,transparent_68%)] blur-3xl md:opacity-95" />
        <div className="absolute bottom-[-8%] left-1/2 h-[min(85vw,42rem)] w-[min(115%,52rem)] -translate-x-1/2 rounded-full bg-[radial-gradient(ellipse_50%_42%_at_50%_40%,rgba(0,217,142,0.11)_0%,transparent_72%)] blur-3xl" />
      </div>
      <div
        className="pointer-events-none absolute inset-0 z-[1] pattern-dots-soft opacity-[0.2] mix-blend-multiply [mask-image:radial-gradient(ellipse_96%_82%_at_50%_38%,black_18%,transparent_74%)] [-webkit-mask-image:radial-gradient(ellipse_96%_82%_at_50%_38%,black_18%,transparent_74%)]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 z-[1] pattern-dots-large opacity-[0.055] mix-blend-multiply [mask-image:radial-gradient(ellipse_88%_75%_at_50%_42%,black_25%,transparent_78%)] [-webkit-mask-image:radial-gradient(ellipse_88%_75%_at_50%_42%,black_25%,transparent_78%)]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 z-[1] mesh-hero-depth-clouds opacity-[0.32] md:opacity-[0.38]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 z-[1] mesh-hero-depth-lines opacity-[0.45] md:opacity-[0.5]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 z-[1] mesh-hero-depth-particles opacity-[0.55] md:opacity-[0.62]"
        aria-hidden
      />
      <div className="pointer-events-none absolute inset-0 z-[1] noise-overlay-soft opacity-[0.38]" aria-hidden />
      <div
        className="pointer-events-none absolute inset-0 z-[1] noise-overlay-fine opacity-[0.16] mix-blend-soft-light md:opacity-[0.2]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 z-[1] bg-[radial-gradient(ellipse_100%_78%_at_50%_42%,rgba(255,255,255,0.16)_0%,transparent_52%)]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 z-[1] bg-[radial-gradient(ellipse_100%_88%_at_50%_58%,transparent_36%,rgba(0,0,0,0.026)_100%)]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 z-[1] shadow-[inset_0_0_100px_rgba(255,255,255,0.22),inset_0_0_56px_rgba(0,0,0,0.01),inset_0_-40px_64px_rgba(0,0,0,0.024)]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-x-0 top-0 z-[1] h-px bg-gradient-to-r from-transparent via-black/[0.06] to-transparent"
        aria-hidden
      />

      <div className="pointer-events-none absolute inset-0 z-[12] mesh-hero-field-grid" aria-hidden />

      <Container className="relative z-20">
        <motion.div
          className="mx-auto text-center"
          variants={staggerContainer}
          initial="hidden"
          animate="visible"
        >
          <motion.h1
            className="text-hero font-bold tracking-tight text-gray-900 sm:whitespace-nowrap"
            variants={fadeInUp}
          >
            {t("title")}
          </motion.h1>

          <motion.p
            className="mx-auto mt-6 max-w-2xl text-balance text-base leading-relaxed text-gray-600 md:text-lg md:leading-relaxed"
            variants={fadeInUp}
          >
            {t("subtitle")}
          </motion.p>

          <motion.div
            id="download"
            className="mt-10 flex flex-wrap items-center justify-center gap-3 sm:gap-4"
            variants={fadeInUp}
          >
            <AppStoreButton store="apple" />
            <AppStoreButton store="google" />
          </motion.div>
        </motion.div>

        <div className="relative mx-auto mt-12 max-w-5xl md:mt-16">
          <div
            className="absolute inset-x-[6%] -bottom-2 top-[38%] rounded-[2rem] bg-gradient-to-b from-white via-gray-100/95 to-gray-200/80 shadow-[0_14px_40px_rgba(0,0,0,0.045),0_6px_20px_rgba(0,0,0,0.03)] ring-1 ring-black/[0.05] md:inset-x-[10%] md:top-[35%] md:rounded-[2.25rem]"
            aria-hidden
          />
          <div className="relative flex items-end justify-center pb-2">
            <div className="flex w-full justify-center md:hidden">
              <HeroPhoneSwipeDeck />
            </div>

            <div className="hidden w-full items-end justify-center gap-2 sm:gap-4 md:flex md:gap-6">
              <FloatingPhone className="w-56 lg:w-64" delay={0.05}>
                <PhoneMockup>
                  <PhoneScreen variant="login" />
                </PhoneMockup>
              </FloatingPhone>

              <FloatingPhone className="z-10 w-[min(100%,17.5rem)] sm:w-60 lg:w-72" delay={0.15}>
                <PhoneMockup>
                  <PhoneScreen variant="welcome" />
                </PhoneMockup>
              </FloatingPhone>

              <FloatingPhone className="w-56 lg:w-64" delay={0.25}>
                <PhoneMockup>
                  <PhoneScreen variant="map" />
                </PhoneMockup>
              </FloatingPhone>
            </div>
          </div>
        </div>
      </Container>

      {/* Ramp: eases grid + gray field into the wave / next section (How it works uses #f8fafc). */}
      <div
        className="pointer-events-none absolute inset-x-0 bottom-0 z-[14] h-24 bg-gradient-to-b from-transparent via-white/14 to-[#f8fafc] sm:h-28 md:h-36 md:via-white/18 lg:h-[10.5rem]"
        aria-hidden
      />

      <div className="pointer-events-none absolute inset-x-0 bottom-0 z-[15]" aria-hidden>
        <svg
          className="block h-12 w-full md:h-16 lg:h-[4.25rem] [shape-rendering:geometricPrecision]"
          viewBox="0 0 1440 72"
          preserveAspectRatio="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="heroWaveFill" x1="0" y1="0" x2="0" y2="1" gradientUnits="objectBoundingBox">
              <stop offset="0%" stopColor="#e6e8ec" />
              <stop offset="38%" stopColor="#f2f3f5" />
              <stop offset="100%" stopColor="#f8fafc" />
            </linearGradient>
            <filter
              id="heroWaveEdgeSoft"
              x="-15%"
              y="-70%"
              width="130%"
              height="200%"
              colorInterpolationFilters="sRGB"
            >
              <feGaussianBlur in="SourceGraphic" stdDeviation="2.5" />
            </filter>
          </defs>
          <path
            fill="#ffffff"
            d="M0 72V42c120-18 280-18 400-6 160 16 320 16 480 0 140-14 360-20 560 8v28H0z"
            filter="url(#heroWaveEdgeSoft)"
            opacity={0.28}
            transform="translate(0 -2)"
          />
          <path fill="url(#heroWaveFill)" d="M0 72V42c120-18 280-18 400-6 160 16 320 16 480 0 140-14 360-20 560 8v28H0z" />
        </svg>
      </div>
    </Section>
  );
}

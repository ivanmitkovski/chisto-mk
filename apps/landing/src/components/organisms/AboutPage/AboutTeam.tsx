"use client";

import { useCallback, useEffect } from "react";
import Image from "next/image";
import { ChevronLeft, ChevronRight, UserRound } from "lucide-react";
import useEmblaCarousel from "embla-carousel-react";
import { motion } from "framer-motion";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { fadeInUp, viewOnce } from "@/lib/animations/variants";
import type { AboutCreator } from "./about-page.types";

type AboutTeamProps = {
  sectionTitle: string;
  photoPlaceholder: string;
  carouselPrevLabel: string;
  carouselNextLabel: string;
  creators: AboutCreator[];
};

const carouselBtnClass =
  "inline-flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-gray-200/90 bg-white text-gray-700 shadow-sm transition-colors hover:border-primary/30 hover:bg-primary/5 hover:text-primary-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 md:h-12 md:w-12";

/** Names that are clearly “to be announced” copy — show icon instead of initials. */
function isPlaceholderDisplayName(name: string): boolean {
  const n = name.trim();
  if (!n) return true;
  if (/^tbc$/i.test(n)) return true;
  if (/наскоро/i.test(n)) return true;
  if (/më vonë/i.test(n) || /me vone/i.test(n)) return true;
  return false;
}

function initialsFromName(name: string): string {
  const parts = name
    .trim()
    .split(/\s+/)
    .filter((w) => w.length > 0);
  if (parts.length >= 2) {
    const a = parts[0].charAt(0);
    const b = parts[1].charAt(0);
    return (a + b).toUpperCase();
  }
  if (parts.length === 1 && parts[0].length >= 2) {
    return parts[0].slice(0, 2).toUpperCase();
  }
  if (parts.length === 1 && parts[0].length === 1) {
    return parts[0].toUpperCase();
  }
  return "";
}

function TeamPortraitPlaceholder({ name, caption }: { name: string; caption: string }) {
  const useIcon = isPlaceholderDisplayName(name);
  const initials = useIcon ? "" : initialsFromName(name);
  const showInitials = initials.length > 0;

  return (
    <div
      className="relative flex h-full w-full flex-col bg-gradient-to-br from-[var(--color-primary-50)] via-white to-gray-100/90"
      aria-label={caption}
    >
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.35]"
        style={{
          backgroundImage:
            "radial-gradient(circle at 30% 20%, var(--color-primary-100) 0%, transparent 45%), radial-gradient(circle at 80% 70%, var(--color-primary-50) 0%, transparent 40%)",
        }}
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.12]"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='24' height='24' viewBox='0 0 24 24' xmlns='http://www.w3.org/2000/svg'%3E%3Ccircle cx='2' cy='2' r='1' fill='%2300A36B'/%3E%3C/svg%3E")`,
          backgroundSize: "18px 18px",
        }}
        aria-hidden
      />
      <div className="relative flex flex-1 flex-col items-center justify-center px-4 pt-6 pb-2">
        {useIcon || !showInitials ? (
          <div className="rounded-full bg-primary/10 p-5 ring-1 ring-primary/15">
            <UserRound
              className="h-14 w-14 text-primary/40 sm:h-[4.5rem] sm:w-[4.5rem]"
              strokeWidth={1.15}
              aria-hidden
            />
          </div>
        ) : (
          <span
            className="select-none text-4xl font-semibold tracking-tight text-primary/50 tabular-nums sm:text-5xl"
            aria-hidden
          >
            {initials}
          </span>
        )}
      </div>
      <div className="relative border-t border-primary/10 bg-white/55 px-3 py-2.5 backdrop-blur-[6px] supports-[backdrop-filter]:bg-white/40">
        <p className="text-center text-[0.6875rem] font-semibold uppercase tracking-[0.12em] text-gray-500">
          {caption}
        </p>
      </div>
    </div>
  );
}

function TeamMemberSlide({
  creator,
  photoPlaceholder,
  index,
  total,
}: {
  creator: AboutCreator;
  photoPlaceholder: string;
  index: number;
  total: number;
}) {
  const src = creator.imageSrc?.trim();
  return (
    <div
      className="min-w-0 shrink-0 grow-0 basis-full pl-5 md:basis-1/2 md:pl-6 lg:basis-1/3 lg:pl-8"
      role="group"
      aria-roledescription="slide"
      aria-label={`${index + 1} / ${total}`}
    >
      <div className="flex h-full min-h-0 flex-col px-1">
        <div className="relative mx-auto aspect-[3/4] w-full max-w-[220px] shrink-0 overflow-hidden rounded-2xl bg-gray-100/90 shadow-sm ring-1 ring-gray-200/85 sm:mx-0 sm:max-w-none">
          {src ? (
            <Image
              src={src}
              alt={creator.imageAlt}
              fill
              className="object-cover"
              sizes="(max-width:768px) 90vw, (max-width:1024px) 45vw, 33vw"
            />
          ) : (
            <TeamPortraitPlaceholder name={creator.name} caption={photoPlaceholder} />
          )}
        </div>
        <div className="mt-4 flex min-h-0 flex-1 flex-col text-center sm:text-left">
          <p className="text-about-team-name text-balance">{creator.name}</p>
          <p className="mt-1.5 flex-1 text-pretty text-about-prose">{creator.role}</p>
        </div>
      </div>
    </div>
  );
}

export function AboutTeam({
  sectionTitle,
  photoPlaceholder,
  carouselPrevLabel,
  carouselNextLabel,
  creators,
}: AboutTeamProps) {
  const [emblaRef, emblaApi] = useEmblaCarousel({
    loop: true,
    align: "start",
    slidesToScroll: 1,
    dragFree: false,
  });

  useEffect(() => {
    emblaApi?.reInit();
  }, [emblaApi, creators]);

  const scrollPrev = useCallback(() => emblaApi?.scrollPrev(), [emblaApi]);
  const scrollNext = useCallback(() => emblaApi?.scrollNext(), [emblaApi]);

  const total = creators.length;

  return (
    <Section
      id="about-team"
      className="scroll-mt-24 relative overflow-hidden border-t border-gray-200/50 md:scroll-mt-28 mesh-section-about-closure"
      aria-labelledby="about-team-heading"
    >
      <div
        className="pointer-events-none absolute inset-0 pattern-diagonal-soft opacity-[0.06]"
        aria-hidden
      />
      <Container className="relative z-10 py-[var(--section-y-tight)] md:py-[var(--section-y-lg)]">
        <motion.h2
          id="about-team-heading"
          className="mx-auto max-w-3xl text-center text-about-section-title text-balance"
          variants={fadeInUp}
          initial="hidden"
          whileInView="visible"
          viewport={viewOnce}
        >
          {sectionTitle}
        </motion.h2>

        <div
          className="mt-10 sm:mt-12"
          role="region"
          aria-roledescription="carousel"
          aria-label={sectionTitle}
        >
          <div className="flex items-center gap-2 sm:gap-3 md:gap-4">
            <button type="button" className={carouselBtnClass} aria-label={carouselPrevLabel} onClick={scrollPrev}>
              <ChevronLeft className="h-5 w-5 md:h-6 md:w-6" aria-hidden />
            </button>

            <div className="min-w-0 flex-1 overflow-hidden py-1" ref={emblaRef}>
              <div className="-ml-5 flex touch-pan-y md:-ml-6 lg:-ml-8">
                {creators.map((creator, index) => (
                  <TeamMemberSlide
                    key={`${creator.name}-${index}`}
                    creator={creator}
                    photoPlaceholder={photoPlaceholder}
                    index={index}
                    total={total}
                  />
                ))}
              </div>
            </div>

            <button type="button" className={carouselBtnClass} aria-label={carouselNextLabel} onClick={scrollNext}>
              <ChevronRight className="h-5 w-5 md:h-6 md:w-6" aria-hidden />
            </button>
          </div>
        </div>
      </Container>
    </Section>
  );
}

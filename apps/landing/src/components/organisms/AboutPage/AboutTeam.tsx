"use client";

import { useId } from "react";
import Image from "next/image";
import { UserRound } from "lucide-react";
import { motion, useReducedMotion } from "framer-motion";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { SocialIcon } from "@/components/molecules/SocialIcon";
import { fadeInUp } from "@/lib/animations/variants";
import type { AboutCreator } from "./about-page.types";

type AboutTeamProps = {
  sectionTitle: string;
  sectionLead?: string;
  photoPlaceholder: string;
  linkedinAria: (name: string) => string;
  creators: AboutCreator[];
};

const cardViewport = { once: true as const, amount: 0.12 as const, margin: "0px 0px -8% 0px" };

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
  const useBrandMark = /chisto/i.test(name);
  const useIcon = !useBrandMark && isPlaceholderDisplayName(name);
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
        {useBrandMark ? (
          <Image
            src="/brand/chisto-mark-green.svg"
            alt=""
            width={80}
            height={92}
            className="h-20 w-auto opacity-90"
            unoptimized
          />
        ) : useIcon || !showInitials ? (
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

function TeamMemberCard({
  creator,
  photoPlaceholder,
  linkedinAria,
  priority,
}: {
  creator: AboutCreator;
  photoPlaceholder: string;
  linkedinAria: string;
  priority: boolean;
}) {
  const nameId = useId();
  const src = creator.imageSrc?.trim();
  const linkedinUrl = creator.linkedinUrl?.trim();
  const role = creator.role?.trim();
  const affiliation = creator.affiliation?.trim();

  return (
    <article
      aria-labelledby={nameId}
      className="mx-auto flex h-full w-full max-w-sm flex-col rounded-3xl bg-white/70 p-5 text-center shadow-sm ring-1 ring-gray-200/80 transition-[box-shadow,ring-color] duration-300 ease-out hover:shadow-[var(--shadow-lift)] hover:ring-gray-300/80 sm:p-6 md:mx-0 md:max-w-none"
    >
      <div className="relative aspect-[4/5] w-full overflow-hidden rounded-2xl bg-gray-100 ring-1 ring-gray-200/70">
        {src ? (
          <Image
            src={src}
            alt={creator.imageAlt}
            fill
            quality={90}
            priority={priority}
            className="object-cover object-top"
            sizes="(max-width: 768px) 280px, (max-width: 1024px) 360px, 320px"
          />
        ) : (
          <TeamPortraitPlaceholder name={creator.name} caption={photoPlaceholder} />
        )}
      </div>

      <div className="mt-5 flex min-h-0 flex-1 flex-col items-center">
        <h3 id={nameId} className="text-about-team-name text-balance">
          {creator.name}
        </h3>
        <p className="mt-1.5 text-[1.0625rem] font-semibold tracking-[-0.018em] text-primary-text md:text-[1.125rem]">
          {creator.title}
        </p>
        {role ? <p className="mt-1 text-pretty text-about-prose">{role}</p> : null}
        {affiliation ? (
          <p className="mt-1 text-pretty text-sm leading-snug text-gray-500 md:text-[0.9375rem] md:leading-snug">
            {affiliation}
          </p>
        ) : null}

        {linkedinUrl ? (
          <div className="mt-auto flex w-full flex-col items-center pt-4">
            <SocialIcon
              platform="linkedin"
              href={linkedinUrl}
              ariaLabel={linkedinAria}
              className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
            />
          </div>
        ) : null}
      </div>
    </article>
  );
}

export function AboutTeam({
  sectionTitle,
  sectionLead,
  photoPlaceholder,
  linkedinAria,
  creators,
}: AboutTeamProps) {
  const reduceMotion = useReducedMotion() ?? false;
  const lead = sectionLead?.trim();

  return (
    <Section
      id="about-team"
      className="scroll-mt-24 relative overflow-x-clip border-t border-gray-200/50 md:scroll-mt-28 mesh-section-about-closure"
      aria-labelledby="about-team-heading"
    >
      <div
        className="pointer-events-none absolute inset-0 pattern-diagonal-soft opacity-[0.06]"
        aria-hidden
      />
      <Container className="relative z-10 py-[var(--section-y-tight)] md:py-[var(--section-y-lg)]">
        <div className="mx-auto max-w-3xl text-center">
          <motion.h2
            id="about-team-heading"
            className="text-about-section-title text-balance"
            variants={fadeInUp}
            initial={reduceMotion ? false : "hidden"}
            whileInView="visible"
            viewport={cardViewport}
          >
            {sectionTitle}
          </motion.h2>
          {lead ? (
            <motion.p
              className="mx-auto mt-3 max-w-xl text-pretty text-about-prose"
              variants={fadeInUp}
              initial={reduceMotion ? false : "hidden"}
              whileInView="visible"
              viewport={cardViewport}
            >
              {lead}
            </motion.p>
          ) : null}
        </div>

        {creators.length > 0 ? (
          <ul
            className="mx-auto mt-10 grid max-w-5xl list-none grid-cols-1 items-stretch gap-8 sm:mt-12 md:grid-cols-2 md:gap-10 lg:gap-12"
            role="list"
          >
            {creators.map((creator, index) => (
              <motion.li
                key={creator.name}
                className="min-w-0"
                variants={fadeInUp}
                initial={reduceMotion ? false : "hidden"}
                whileInView="visible"
                viewport={cardViewport}
              >
                <TeamMemberCard
                  creator={creator}
                  photoPlaceholder={photoPlaceholder}
                  linkedinAria={linkedinAria(creator.name)}
                  priority={index < 2}
                />
              </motion.li>
            ))}
          </ul>
        ) : null}
      </Container>
    </Section>
  );
}

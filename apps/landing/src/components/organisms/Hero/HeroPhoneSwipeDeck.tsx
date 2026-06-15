"use client";

import { motion, useReducedMotion, type PanInfo } from "framer-motion";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useCallback, useEffect, useRef, useState, type KeyboardEvent } from "react";
import { useTranslations } from "next-intl";
import {
  HERO_PHONE_VARIANTS,
  PhoneScreen,
  type HeroPhoneVariant,
} from "@/components/molecules/PhoneDemoScreens";
import { PhoneMockup } from "@/components/molecules/PhoneMockup";
import { cn } from "@/lib/utils/cn";

const COUNT = HERO_PHONE_VARIANTS.length;

/** Once dismissed (or completed), never show again — survives refresh. */
const GESTURE_HINT_STORAGE_KEY = "chisto.hero.phoneDeck.gestureHint.v1";

function stackRank(i: number, activeIndex: number) {
  return (i - activeIndex + COUNT) % COUNT;
}

const DRAG_DISTANCE = 52;
const DRAG_VELOCITY = 420;

/** Matches keyframe + chevron timing; failsafe timeout adds slack if completion never fires. */
const HINT_ANIMATION_DURATION_S = 2.8;
const HINT_FAILSAFE_MS = Math.round(HINT_ANIMATION_DURATION_S * 1000) + 800;

const SHADOW_FRONT =
  "shadow-[0_22px_52px_rgba(0,0,0,0.11),0_8px_24px_rgba(0,0,0,0.06)]";
const SHADOW_BACK =
  "shadow-[0_12px_32px_rgba(0,0,0,0.06),0_4px_14px_rgba(0,0,0,0.04)]";

const slideLabelKey = (v: HeroPhoneVariant) => {
  switch (v) {
    case "login":
      return "phoneDeckSlideLogin" as const;
    case "welcome":
      return "phoneDeckSlideWelcome" as const;
    case "map":
      return "phoneDeckSlideMap" as const;
  }
};

export function HeroPhoneSwipeDeck() {
  const t = useTranslations("hero");
  const reduceMotionPref = useReducedMotion();
  const reduceMotion = reduceMotionPref === true;
  const [activeIndex, setActiveIndex] = useState(1);
  const hintDismissedRef = useRef(false);
  const gestureHintActiveRef = useRef(false);
  const [gestureHintActive, setGestureHintActive] = useState(false);

  gestureHintActiveRef.current = gestureHintActive;

  useEffect(() => {
    if (reduceMotionPref === true) {
      setGestureHintActive(false);
      return;
    }
    /* Wait until Framer has resolved prefers-reduced-motion (avoids a flash for a11y users). */
    if (reduceMotionPref === null) return;

    try {
      if (globalThis.localStorage?.getItem(GESTURE_HINT_STORAGE_KEY)) return;
    } catch {
      return;
    }
    setGestureHintActive(true);
  }, [reduceMotionPref]);

  const dismissGestureHint = useCallback(() => {
    if (hintDismissedRef.current) return;
    hintDismissedRef.current = true;
    try {
      globalThis.localStorage?.setItem(GESTURE_HINT_STORAGE_KEY, "1");
    } catch {
      /* private / blocked storage */
    }
    setGestureHintActive(false);
  }, []);

  useEffect(() => {
    if (!gestureHintActive) return;
    const id = globalThis.setTimeout(() => dismissGestureHint(), HINT_FAILSAFE_MS);
    return () => globalThis.clearTimeout(id);
  }, [gestureHintActive, dismissGestureHint]);

  const transition = reduceMotion
    ? { duration: 0.18, ease: "easeOut" as const }
    : { type: "spring" as const, stiffness: 380, damping: 34, mass: 0.85 };

  const onDragEnd = useCallback(
    (slideIndex: number, info: PanInfo) => {
      if (reduceMotion) return;
      const { offset, velocity } = info;
      setActiveIndex((current) => {
        if (slideIndex !== current) return current;
        let delta = 0;
        if (offset.x < -DRAG_DISTANCE || velocity.x < -DRAG_VELOCITY) delta = 1;
        else if (offset.x > DRAG_DISTANCE || velocity.x > DRAG_VELOCITY) delta = -1;
        if (delta === 0) return current;
        return (current + delta + COUNT) % COUNT;
      });
    },
    [reduceMotion],
  );

  const onKeyDown = useCallback(
    (e: KeyboardEvent<HTMLDivElement>) => {
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        dismissGestureHint();
        setActiveIndex((i) => (i - 1 + COUNT) % COUNT);
      } else if (e.key === "ArrowRight") {
        e.preventDefault();
        dismissGestureHint();
        setActiveIndex((i) => (i + 1) % COUNT);
      }
    },
    [dismissGestureHint],
  );

  return (
    <div
      role="region"
      aria-label={t("phoneDeckRegionLabel")}
      tabIndex={reduceMotion ? -1 : 0}
      onKeyDown={onKeyDown}
      className="relative mx-auto w-[min(100%,17.5rem)] touch-pan-y outline-none focus-visible:rounded-xl focus-visible:ring-2 focus-visible:ring-primary/40 focus-visible:ring-offset-2"
    >
      <div className="relative overflow-visible pb-7">
        <div className="relative aspect-[9/19.5] w-full">
          {HERO_PHONE_VARIANTS.map((variant, i) => {
            const d = stackRank(i, activeIndex);
            const isFront = d === 0;
            const x = d === 0 ? 0 : 10 + d * 10;
            const y = d * 11;
            const scale = 1 - 0.065 * d;
            const opacity = d === 0 ? 1 : d === 1 ? 0.84 : 0.56;
            const rotateZ = d === 0 ? 0 : d === 1 ? 1.4 : 2.8;

            return (
              <motion.div
                key={variant}
                className={cn(
                  "absolute left-0 right-0 top-0 mx-auto w-full",
                  !isFront && "pointer-events-none",
                )}
                style={{
                  zIndex: 30 - d * 10,
                  transformOrigin: "50% 0%",
                }}
                animate={{ x, y, scale, opacity, rotateZ }}
                transition={transition}
                drag={isFront && !reduceMotion ? "x" : false}
                dragConstraints={{ left: -130, right: 130 }}
                dragElastic={0.12}
                {...(isFront ? { onDragStart: dismissGestureHint } : {})}
                onDragEnd={(_, info) => onDragEnd(i, info)}
              >
                {isFront ? (
                  <motion.div
                    className="relative"
                    animate={
                      gestureHintActive
                        ? { x: [0, -12, 12, -7, 7, 0] }
                        : { x: 0 }
                    }
                    transition={
                      gestureHintActive
                        ? {
                            duration: HINT_ANIMATION_DURATION_S,
                            times: [0, 0.14, 0.32, 0.52, 0.72, 1],
                            ease: [0.33, 0, 0.25, 1],
                          }
                        : { type: "spring", stiffness: 440, damping: 36 }
                    }
                    onAnimationComplete={() => {
                      if (gestureHintActiveRef.current) dismissGestureHint();
                    }}
                  >
                    <PhoneMockup className={SHADOW_FRONT}>
                      <PhoneScreen variant={variant} />
                    </PhoneMockup>
                    {gestureHintActive ? (
                      <motion.div
                        className="pointer-events-none absolute inset-x-0 bottom-9 flex justify-between px-5"
                        aria-hidden
                        initial={{ opacity: 0 }}
                        animate={{ opacity: [0, 0.5, 0.32, 0.48, 0] }}
                        transition={{
                          duration: HINT_ANIMATION_DURATION_S,
                          times: [0, 0.18, 0.4, 0.62, 1],
                          ease: "easeInOut",
                        }}
                      >
                        <ChevronLeft className="size-[17px] text-gray-500/55" strokeWidth={2} />
                        <ChevronRight className="size-[17px] text-gray-500/55" strokeWidth={2} />
                      </motion.div>
                    ) : null}
                  </motion.div>
                ) : (
                  <PhoneMockup className={SHADOW_BACK}>
                    <PhoneScreen variant={variant} />
                  </PhoneMockup>
                )}
              </motion.div>
            );
          })}
        </div>
      </div>

      {reduceMotion ? (
        <div
          className="mt-1 flex justify-center gap-2.5"
          role="tablist"
          aria-orientation="horizontal"
          aria-label={t("phoneDeckDotsLabel")}
        >
          {HERO_PHONE_VARIANTS.map((variant, i) => (
            <button
              key={variant}
              type="button"
              role="tab"
              aria-selected={activeIndex === i}
              tabIndex={activeIndex === i ? 0 : -1}
              aria-label={t(slideLabelKey(variant))}
              onClick={() => setActiveIndex(i)}
              className={cn(
                "h-2.5 w-2.5 rounded-full transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:ring-offset-2",
                activeIndex === i ? "bg-primary" : "bg-gray-300 hover:bg-gray-400",
              )}
            />
          ))}
        </div>
      ) : null}
    </div>
  );
}

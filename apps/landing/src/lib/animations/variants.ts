import type { Variants } from "framer-motion";

/** Reference ease for non-spring segments (line draws, etc.) */
export const easeOutExpo: [number, number, number, number] = [0.22, 1, 0.36, 1];

const springReveal = {
  type: "spring" as const,
  stiffness: 380,
  damping: 32,
  mass: 0.9,
};

const springRevealTight = {
  type: "spring" as const,
  stiffness: 440,
  damping: 36,
  mass: 0.82,
};

export const transitionSmooth = {
  duration: 0.72,
  ease: easeOutExpo,
};

export const transitionMedium = {
  duration: 0.52,
  ease: easeOutExpo,
};

export const viewOnce = { once: true as const, amount: 0.22 as const };

export const fadeInUp: Variants = {
  hidden: { opacity: 0, y: 24 },
  visible: {
    opacity: 1,
    y: 0,
    transition: springReveal,
  },
};

export const fadeInUpTight: Variants = {
  hidden: { opacity: 0, y: 14 },
  visible: {
    opacity: 1,
    y: 0,
    transition: springRevealTight,
  },
};

export const scaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.94 },
  visible: {
    opacity: 1,
    scale: 1,
    transition: { type: "spring", stiffness: 400, damping: 28, mass: 0.85 },
  },
};

export const slideInLeft: Variants = {
  hidden: { opacity: 0, x: -40 },
  visible: {
    opacity: 1,
    x: 0,
    transition: springReveal,
  },
};

export const slideInRight: Variants = {
  hidden: { opacity: 0, x: 40 },
  visible: {
    opacity: 1,
    x: 0,
    transition: springReveal,
  },
};

export const staggerContainer: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.06,
      when: "beforeChildren" as const,
    },
  },
};

export const staggerContainerLoose: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.14,
      delayChildren: 0.1,
      when: "beforeChildren" as const,
    },
  },
};

export const lineReveal: Variants = {
  hidden: { scaleX: 0, opacity: 0 },
  visible: {
    scaleX: 1,
    opacity: 1,
    transition: { duration: 0.95, ease: easeOutExpo },
  },
};

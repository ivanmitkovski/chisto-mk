"use client";

import { MotionConfig } from "framer-motion";

/** Apple-like default: snappy spring, not bouncy */
const defaultTransition = {
  type: "spring" as const,
  stiffness: 420,
  damping: 34,
  mass: 0.88,
};

export function MotionProvider({ children }: { children: React.ReactNode }) {
  return (
    <MotionConfig reducedMotion="user" transition={defaultTransition}>
      {children}
    </MotionConfig>
  );
}

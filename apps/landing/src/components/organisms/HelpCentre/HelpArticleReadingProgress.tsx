"use client";

import { useEffect, useState } from "react";
import { useReducedMotion } from "framer-motion";

/**
 * Thin fixed progress bar from scroll depth. Omitted entirely when the user prefers reduced motion
 * so we avoid non-essential animation (WCAG 2.2: 2.3.3 Animation from Interactions). The bar is
 * decorative only (`aria-hidden`); do not use it as the sole reading-progress indicator for SR users.
 */
export function HelpArticleReadingProgress() {
  const reduceMotion = useReducedMotion();
  const [ratio, setRatio] = useState(0);

  useEffect(() => {
    if (reduceMotion) return;

    const update = () => {
      const el = document.documentElement;
      const scrollTop = window.scrollY;
      const maxScroll = el.scrollHeight - window.innerHeight;
      const next = maxScroll <= 0 ? 0 : scrollTop / maxScroll;
      setRatio(Math.min(1, Math.max(0, next)));
    };

    update();
    window.addEventListener("scroll", update, { passive: true });
    window.addEventListener("resize", update);
    return () => {
      window.removeEventListener("scroll", update);
      window.removeEventListener("resize", update);
    };
  }, [reduceMotion]);

  if (reduceMotion) {
    return null;
  }

  return (
    <div
      className="pointer-events-none fixed inset-x-0 top-0 z-[70] h-0.5 bg-gray-200/80"
      aria-hidden
    >
      <div
        className="h-full origin-left bg-primary motion-safe:transition-transform motion-safe:duration-150 motion-safe:ease-out"
        style={{ transform: `scaleX(${ratio})` }}
      />
    </div>
  );
}

"use client";

import { motion, useInView, useReducedMotion } from "framer-motion";
import { useEffect, useRef, useState } from "react";
import { easeOutExpo } from "@/lib/animations/variants";
import { cn } from "@/lib/utils/cn";

/** Low threshold + once; reveal state is latched so IO can never replay the entrance while scrolling. */
const phoneRevealInView = {
  once: true as const,
  amount: 0.06 as const,
};

interface FloatingPhoneProps {
  children: React.ReactNode;
  className?: string;
  delay?: number;
  rotate?: number;
}

export function FloatingPhone({
  children,
  className,
  delay = 0,
  rotate = 0,
}: FloatingPhoneProps) {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, phoneRevealInView);
  const [revealed, setRevealed] = useState(false);
  const reduceMotion = useReducedMotion();

  useEffect(() => {
    if (inView) setRevealed(true);
  }, [inView]);

  return (
    <div ref={ref} className={cn("relative", className)}>
      <motion.div
        initial={{ opacity: 0, y: 52, rotate }}
        animate={revealed ? { opacity: 1, y: 0, rotate } : { opacity: 0, y: 52, rotate }}
        transition={{
          duration: 0.88,
          delay,
          ease: easeOutExpo,
        }}
        className="isolate"
      >
        <div
          className={cn(!reduceMotion && revealed && "animate-float-slow")}
          style={
            !reduceMotion && revealed
              ? { animationDelay: `${delay + 0.25}s` }
              : undefined
          }
        >
          {children}
        </div>
      </motion.div>
    </div>
  );
}

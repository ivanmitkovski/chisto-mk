"use client";

import { motion, useReducedMotion } from "framer-motion";
import { fadeInUp, viewOnce } from "@/lib/animations/variants";
import { cn } from "@/lib/utils/cn";

export function MarketingReveal({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  const reduceMotion = useReducedMotion();

  return (
    <motion.div
      className={cn(className)}
      initial={reduceMotion ? false : "hidden"}
      whileInView="visible"
      viewport={viewOnce}
      variants={fadeInUp}
    >
      {children}
    </motion.div>
  );
}

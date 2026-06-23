"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/utils/cn";

interface FAQItemProps {
  title: string;
  content: string;
  variant: "green" | "white";
}

export function FAQItem({ title, content, variant }: FAQItemProps) {
  const isGreen = variant === "green";

  return (
    <motion.article
      className={cn(
        "flex min-h-[11.5rem] flex-col rounded-2xl p-6 md:min-h-[12.5rem] md:rounded-3xl md:p-8",
        isGreen
          ? "bg-gradient-to-br from-primary via-primary-500 to-primary-700 text-white shadow-[var(--shadow-card)] ring-1 ring-white/30"
          : "border border-gray-200/90 bg-white text-gray-900 shadow-[var(--shadow-card)] ring-1 ring-black/[0.04] transition-[border-color,box-shadow] duration-300 hover:border-primary/35 hover:shadow-[var(--shadow-lift)]",
      )}
      whileHover={{
        y: -4,
        transition: { type: "spring", stiffness: 420, damping: 22 },
      }}
    >
      <h3
        className={cn(
          "mb-3 text-lg font-bold leading-snug tracking-tight md:text-xl",
          isGreen ? "text-white" : "text-gray-900",
        )}
      >
        {title}
      </h3>
      <p
        className={cn(
          "text-sm leading-relaxed md:text-[0.9375rem]",
          isGreen ? "text-white/92" : "text-gray-600",
        )}
      >
        {content}
      </p>
    </motion.article>
  );
}

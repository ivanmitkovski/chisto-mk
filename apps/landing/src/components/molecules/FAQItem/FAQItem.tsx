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
    <motion.div
      className={cn(
        "flex min-h-[11.5rem] flex-col rounded-2xl p-6 md:min-h-[12.5rem] md:rounded-3xl md:p-8",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
        isGreen
          ? "bg-gradient-to-br from-primary via-primary-500 to-primary-700 text-white shadow-[0_24px_56px_rgba(0,217,142,0.45),inset_0_1px_0_rgba(255,255,255,0.2)] ring-1 ring-white/30"
          : "border border-gray-200/90 bg-white text-gray-900 shadow-[0_10px_36px_rgba(0,0,0,0.06)] ring-1 ring-black/[0.04] transition-[border-color,box-shadow] duration-300 hover:border-primary/35 hover:shadow-[0_16px_48px_rgba(0,217,142,0.12)]",
      )}
      whileHover={{
        y: -4,
        transition: { type: "spring", stiffness: 420, damping: 22 },
      }}
      whileTap={{ scale: 0.998 }}
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
    </motion.div>
  );
}

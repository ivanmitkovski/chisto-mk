"use client";

import { motion, useReducedMotion } from "framer-motion";
import { ChevronRight } from "lucide-react";
import { Link } from "@/i18n/routing";
import { fadeInUpTight } from "@/lib/animations/variants";
import { cn } from "@/lib/utils/cn";
import type { HelpArticleSlug } from "@/lib/help/help-catalog";
import { helpSearchHighlight } from "./help-search-highlight";

export function HelpTopicCard({
  slug,
  title,
  summary,
  readTime,
  index,
  selected = false,
  highlightQuery = "",
}: {
  slug: HelpArticleSlug;
  title: string;
  summary: string;
  readTime: string;
  index: number;
  selected?: boolean;
  highlightQuery?: string;
}) {
  const reduceMotion = useReducedMotion();

  /** Listbox selection styling on the card applies regardless of motion; Framer only gates enter animation. */
  const inner = (
    <div
      className={cn(
        "group flex h-full flex-col rounded-2xl border border-gray-200/90 bg-white/90 p-5 shadow-sm shadow-black/[0.03] transition-[border-color,box-shadow,transform] duration-300 ease-out",
        "hover:border-primary/25 hover:shadow-md hover:shadow-primary/[0.07]",
        selected && "border-primary/40 ring-2 ring-primary/35",
      )}
    >
      <div className="flex min-h-0 min-w-0 flex-1 flex-col gap-2">
        <h3 className="text-balance font-semibold tracking-tight text-gray-900">{helpSearchHighlight(title, highlightQuery)}</h3>
        <p className="text-pretty text-sm leading-relaxed text-gray-600">{helpSearchHighlight(summary, highlightQuery)}</p>
        <p className="text-xs font-medium tabular-nums text-gray-500">{readTime}</p>
      </div>
      <div className="mt-auto flex justify-end border-t border-gray-100/80 pt-3 text-primary/90 transition-opacity group-hover:text-primary">
        <ChevronRight
          className="h-5 w-5 shrink-0 transition-transform duration-300 ease-out group-hover:translate-x-0.5"
          strokeWidth={2}
          aria-hidden
        />
      </div>
    </div>
  );

  if (reduceMotion) {
    return (
      <Link href={`/help/${slug}`} className="block h-full outline-none ring-offset-2 focus-visible:ring-2 focus-visible:ring-primary">
        {inner}
      </Link>
    );
  }

  return (
    <motion.div
      className="h-full"
      variants={fadeInUpTight}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, amount: 0.2 }}
      transition={{ delay: Math.min(index, 8) * 0.04 }}
    >
      <Link href={`/help/${slug}`} className="block h-full outline-none ring-offset-2 focus-visible:ring-2 focus-visible:ring-primary">
        {inner}
      </Link>
    </motion.div>
  );
}

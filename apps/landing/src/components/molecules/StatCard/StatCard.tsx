"use client";

import { motion, useInView } from "framer-motion";
import type { LucideIcon } from "lucide-react";
import { useLocale } from "next-intl";
import { useEffect, useRef, useState } from "react";
import { viewOnce, easeOutExpo } from "@/lib/animations/variants";

interface StatCardProps {
  number: string;
  label: string;
  icon?: LucideIcon;
}

function intlNumberLocale(locale: string) {
  if (locale === "mk") return "mk-MK";
  if (locale === "sq") return "sq-AL";
  return "en-GB";
}

function isNumericStat(raw: string) {
  return /\d/.test(raw.trim());
}

function parseNumericStat(
  raw: string,
  numberLocale: string,
): { target: number; display: (n: number) => string; suffix: string } {
  const trimmed = raw.trim();
  if (trimmed.toLowerCase().endsWith("kg")) {
    const n = parseInt(trimmed.replace(/\D/g, ""), 10) || 0;
    return { target: n, display: (v) => String(v), suffix: "kg" };
  }
  if (trimmed.includes("+")) {
    const n = parseInt(trimmed.replace(/\D/g, ""), 10) || 0;
    return {
      target: n,
      display: (v) => v.toLocaleString(numberLocale),
      suffix: "+",
    };
  }
  const n = parseInt(trimmed.replace(/\D/g, ""), 10) || 0;
  return {
    target: n,
    display: (v) => v.toLocaleString(numberLocale),
    suffix: "",
  };
}

export function StatCard({ number, label, icon: Icon }: StatCardProps) {
  const locale = useLocale();
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, viewOnce);
  const textMode = !isNumericStat(number);
  const { target, display, suffix } = textMode
    ? { target: 0, display: () => "", suffix: "" }
    : parseNumericStat(number, intlNumberLocale(locale));
  const [value, setValue] = useState(0);

  useEffect(() => {
    if (textMode) return;
    if (!inView || target === 0) {
      if (inView) setValue(target);
      return;
    }

    const duration = 1.65;
    const start = performance.now();

    const tick = (now: number) => {
      const t = Math.min((now - start) / (duration * 1000), 1);
      const eased = 1 - (1 - t) ** 3;
      setValue(Math.round(eased * target));
      if (t < 1) requestAnimationFrame(tick);
    };

    const id = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(id);
  }, [inView, target, textMode]);

  return (
    <div ref={ref} className="group h-full text-center">
      <div className="relative flex h-full flex-col overflow-hidden rounded-2xl border border-gray-200/70 bg-white/75 p-6 shadow-[0_8px_32px_-10px_rgba(15,23,42,0.1),0_2px_8px_-4px_rgba(15,23,42,0.04)] ring-1 ring-black/[0.03] backdrop-blur-[8px] transition-[transform,box-shadow,border-color,ring-color] duration-300 ease-out motion-safe:group-hover:-translate-y-0.5 motion-safe:group-hover:border-primary/20 motion-safe:group-hover:shadow-[0_16px_40px_-12px_rgba(15,23,42,0.12),0_0_0_1px_rgba(0,217,142,0.08)] md:p-7">
        <div
          className="pointer-events-none absolute inset-x-0 top-0 h-0.5 bg-gradient-to-r from-transparent via-primary/35 to-transparent opacity-0 transition-opacity duration-300 group-hover:opacity-100"
          aria-hidden
        />
        {Icon ? (
          <div
            className="mx-auto mb-4 flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-primary/[0.11] text-primary ring-1 ring-primary/15"
            aria-hidden
          >
            <Icon className="h-[1.35rem] w-[1.35rem]" strokeWidth={1.65} />
          </div>
        ) : null}
        <motion.div
          className="flex min-h-[3.5rem] flex-col items-center justify-center md:min-h-[4rem]"
          initial={{ opacity: 0, y: 12 }}
          animate={inView ? { opacity: 1, y: 0 } : { opacity: 0, y: 12 }}
          transition={{ duration: 0.55, ease: easeOutExpo }}
        >
          {textMode ? (
            <span className="max-w-[14rem] text-balance text-lg font-bold leading-snug tracking-tight text-gray-900 md:max-w-[16rem] md:text-xl lg:text-[1.35rem]">
              {number.trim()}
            </span>
          ) : (
            <span className="inline-flex max-w-full flex-nowrap items-baseline justify-center gap-0.5 whitespace-nowrap text-[clamp(1.75rem,4vw+1rem,3.25rem)] font-bold leading-none tabular-nums tracking-[-0.02em] text-gray-900 md:gap-1">
              <span>{inView ? display(value) : "0"}</span>
              {suffix === "kg" ? (
                <span className="text-[0.5em] font-semibold tracking-normal text-gray-500">kg</span>
              ) : null}
              {suffix === "+" ? (
                <span className="translate-y-[-0.06em] text-[0.55em] font-bold tracking-normal text-gray-800">
                  +
                </span>
              ) : null}
            </span>
          )}
        </motion.div>
        <motion.p
          className="mt-4 text-pretty text-[0.8125rem] font-medium leading-snug tracking-wide text-gray-500 md:text-sm md:font-normal md:leading-relaxed md:tracking-normal md:text-gray-600"
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : { opacity: 0 }}
          transition={{ delay: 0.12, duration: 0.45 }}
        >
          {label}
        </motion.p>
      </div>
    </div>
  );
}

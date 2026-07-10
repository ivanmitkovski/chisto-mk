"use client";

import * as Collapsible from "@radix-ui/react-collapsible";
import { ChevronDown } from "lucide-react";
import { useEffect, useState } from "react";
import type { NewsHeadingTocItem } from "@chisto/news-content/render";
import { cn } from "@/lib/utils/cn";

type NewsArticleTocProps = {
  items: readonly NewsHeadingTocItem[];
  ariaLabel: string;
  mobileTriggerLabel: string;
};

const TOC_MIN_H2 = 3;

export function shouldShowNewsArticleToc(items: readonly NewsHeadingTocItem[]): boolean {
  return items.filter((item) => item.level === 2).length >= TOC_MIN_H2;
}

/**
 * Compact in-column TOC for long news posts. Collapsible on small screens;
 * always visible inline list from `md` up (no sidebar — keeps magazine single column).
 */
export function NewsArticleToc({ items, ariaLabel, mobileTriggerLabel }: NewsArticleTocProps) {
  const [activeId, setActiveId] = useState<string | null>(items[0]?.id ?? null);

  useEffect(() => {
    if (items.length === 0) return;

    function headerOffsetPx(): number {
      if (typeof window === "undefined") return 80;
      return window.matchMedia("(min-width: 768px)").matches ? 80 : 68;
    }

    let raf = 0;
    function updateActiveFromScroll() {
      const offset = headerOffsetPx() + 12;
      let currentId: string | null = items[0]?.id ?? null;
      for (const { id } of items) {
        const el = document.getElementById(id);
        if (!el) continue;
        if (el.getBoundingClientRect().top <= offset) {
          currentId = id;
        }
      }
      setActiveId((prev) => (prev === currentId ? prev : currentId));
    }

    function schedule() {
      if (raf) cancelAnimationFrame(raf);
      raf = window.requestAnimationFrame(() => {
        raf = 0;
        updateActiveFromScroll();
      });
    }

    schedule();
    window.addEventListener("scroll", schedule, { passive: true });
    window.addEventListener("resize", schedule);
    return () => {
      window.removeEventListener("scroll", schedule);
      window.removeEventListener("resize", schedule);
      if (raf) cancelAnimationFrame(raf);
    };
  }, [items]);

  if (!shouldShowNewsArticleToc(items)) return null;

  function linkClass(id: string) {
    return cn(
      "block rounded-md py-1.5 pl-3 text-sm leading-snug text-gray-600 transition-colors",
      "border-l-2 border-transparent hover:text-gray-900",
      activeId === id && "border-primary font-medium text-gray-900",
    );
  }

  const list = (
    <ul className="space-y-0.5">
      {items.map((item) => (
        <li key={item.id}>
          <a href={`#${item.id}`} className={linkClass(item.id)}>
            {item.title}
          </a>
        </li>
      ))}
    </ul>
  );

  return (
    <div className="mt-10 max-w-copy print:hidden md:mt-12">
      <div className="md:hidden">
        <Collapsible.Root defaultOpen={false}>
          <Collapsible.Trigger
            className={cn(
              "group flex w-full items-center justify-between gap-3 rounded-2xl border border-gray-200/80 bg-white/95 px-4 py-3 text-left text-sm font-semibold text-gray-900 shadow-sm",
              "hover:border-primary/25 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
              "data-[state=open]:border-primary/20",
            )}
          >
            <span>{mobileTriggerLabel}</span>
            <ChevronDown
              className="h-5 w-5 shrink-0 text-gray-500 transition-transform duration-200 group-data-[state=open]:rotate-180"
              aria-hidden
            />
          </Collapsible.Trigger>
          <Collapsible.Content className="overflow-hidden data-[state=closed]:hidden">
            <nav aria-label={ariaLabel} className="mt-3 rounded-2xl border border-gray-200/80 bg-white/95 p-4 shadow-sm">
              {list}
            </nav>
          </Collapsible.Content>
        </Collapsible.Root>
      </div>

      <nav
        aria-label={ariaLabel}
        className="hidden rounded-2xl border border-gray-200/70 bg-white/80 p-5 shadow-sm md:block"
      >
        <p className="mb-3 text-xs font-bold uppercase tracking-[0.12em] text-gray-500">{ariaLabel}</p>
        {list}
      </nav>
    </div>
  );
}

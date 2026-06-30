"use client";

import * as Collapsible from "@radix-ui/react-collapsible";
import { ChevronDown } from "lucide-react";
import { useEffect, useState } from "react";
import { cn } from "@/lib/utils/cn";

export type HelpTocItem = { id: string; title: string };

/**
 * In-page TOC: collapsible on small viewports; sticky sidebar on large screens.
 */
export function HelpToc({
  items,
  ariaLabel,
  mobileTriggerLabel,
}: {
  items: readonly HelpTocItem[];
  ariaLabel: string;
  /** Visible label for the mobile disclosure trigger (e.g. “Table of contents”). */
  mobileTriggerLabel: string;
}) {
  const [activeId, setActiveId] = useState<string | null>(items[0]?.id ?? null);

  useEffect(() => {
    if (items.length === 0) return;

    /** Matches marketing header: `h-[4.25rem]` (68px) default, `md:h-20` (80px). */
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
        const top = el.getBoundingClientRect().top;
        if (top <= offset) {
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
    const mq = window.matchMedia("(min-width: 768px)");
    mq.addEventListener("change", schedule);
    return () => {
      window.removeEventListener("scroll", schedule);
      window.removeEventListener("resize", schedule);
      mq.removeEventListener("change", schedule);
      if (raf) cancelAnimationFrame(raf);
    };
  }, [items]);

  function linkClass(id: string) {
    return cn(
      "block rounded-md py-2 pl-3 text-sm leading-snug text-gray-600 transition-colors",
      "border-l-2 border-transparent hover:text-gray-900",
      activeId === id && "border-primary font-medium text-gray-900",
    );
  }

  const list = (
    <ul className="space-y-1">
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
    <div className="min-w-0">
      <div className="lg:hidden">
        <Collapsible.Root defaultOpen={false}>
          <Collapsible.Trigger
            className={cn(
              "flex w-full items-center justify-between gap-3 rounded-2xl border border-gray-200/80 bg-white/95 px-4 py-3 text-left text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-black/[0.04] backdrop-blur-sm",
              "hover:border-primary/25 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
              "data-[state=open]:border-primary/20",
            )}
          >
            <span>{mobileTriggerLabel}</span>
            <ChevronDown
              className="h-5 w-5 shrink-0 text-gray-500 transition-transform duration-200 data-[state=open]:rotate-180"
              aria-hidden
            />
          </Collapsible.Trigger>
          <Collapsible.Content className="overflow-hidden data-[state=closed]:hidden pt-1">
            <nav aria-label={ariaLabel} className="mt-3 rounded-2xl border border-gray-200/80 bg-white/95 p-4 shadow-sm">
              {list}
            </nav>
          </Collapsible.Content>
        </Collapsible.Root>
      </div>

      <div className="hidden lg:block">
        <nav aria-label={ariaLabel} className="min-w-0">
          <div
            className={cn(
              "sticky top-20 z-10 max-h-[min(46vh,calc(100vh-6rem))] overflow-y-auto rounded-2xl border border-gray-200/80 bg-white/95 p-5 shadow-sm ring-1 ring-black/[0.04] backdrop-blur-sm",
              "lg:top-20 lg:max-h-[calc(100vh-6rem)] lg:rounded-none lg:border-0 lg:bg-transparent lg:p-0 lg:pr-2 lg:shadow-none lg:ring-0 lg:backdrop-blur-none",
            )}
          >
            <p className="mb-3 text-xs font-bold uppercase tracking-[0.12em] text-gray-500">{ariaLabel}</p>
            {list}
          </div>
        </nav>
      </div>
    </div>
  );
}

"use client";

import { ChevronDown } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { routing, usePathname, useRouter } from "@/i18n/routing";
import { cn } from "@/lib/utils/cn";
import { useCallback, useEffect, useId, useRef, useState, type KeyboardEvent } from "react";

const LABELS: Record<string, string> = {
  mk: "MK",
  en: "EN",
  sq: "SQ",
};

export function LanguageSelector() {
  const locale = useLocale();
  const pathname = usePathname();
  const router = useRouter();
  const t = useTranslations("common");
  const [open, setOpen] = useState(false);
  const [focusIndex, setFocusIndex] = useState(0);
  const ref = useRef<HTMLDivElement>(null);
  const listboxId = useId();

  const locales = routing.locales;
  const activeIndex = Math.max(0, locales.indexOf(locale as (typeof locales)[number]));

  useEffect(() => {
    function onDocClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("click", onDocClick);
    return () => document.removeEventListener("click", onDocClick);
  }, []);

  useEffect(() => {
    if (open) setFocusIndex(activeIndex);
  }, [open, activeIndex]);

  const selectLocale = useCallback(
    (loc: (typeof locales)[number]) => {
      setOpen(false);
      router.replace(pathname, { locale: loc });
    },
    [pathname, router],
  );

  const onTriggerKeyDown = (e: KeyboardEvent<HTMLButtonElement>) => {
    if (e.key === "Escape") {
      e.preventDefault();
      setOpen(false);
      return;
    }
    if (e.key === "ArrowDown" || e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      setOpen(true);
    }
  };

  const onListKeyDown = (e: KeyboardEvent<HTMLUListElement>) => {
    if (e.key === "Escape") {
      e.preventDefault();
      setOpen(false);
      return;
    }
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setFocusIndex((i) => (i + 1) % locales.length);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setFocusIndex((i) => (i - 1 + locales.length) % locales.length);
    } else if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      const loc = locales[focusIndex];
      if (loc) selectLocale(loc);
    }
  };

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        className="flex items-center gap-2 rounded-full border border-gray-200/90 bg-white/80 px-3 py-1.5 text-[0.8125rem] font-semibold tracking-wide text-gray-800 shadow-sm transition-colors hover:border-gray-300 hover:bg-gray-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
        aria-label={`${t("language")}: ${LABELS[locale] ?? locale}`}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-controls={listboxId}
        onClick={() => setOpen((o) => !o)}
        onKeyDown={onTriggerKeyDown}
      >
        <span className="tabular-nums">{LABELS[locale] ?? locale.toUpperCase()}</span>
        <ChevronDown className="h-3.5 w-3.5 text-gray-500" strokeWidth={2} aria-hidden />
      </button>
      {open ? (
        <ul
          id={listboxId}
          className="absolute right-0 z-50 mt-1 min-w-[5.5rem] rounded-xl border border-gray-200/90 bg-white py-1 shadow-lg ring-1 ring-black/[0.04]"
          role="listbox"
          aria-label={t("language")}
          onKeyDown={onListKeyDown}
        >
          {locales.map((loc, index) => (
            <li key={loc} role="presentation">
              <button
                type="button"
                role="option"
                aria-selected={loc === locale}
                tabIndex={focusIndex === index ? 0 : -1}
                className={cn(
                  "flex w-full items-center px-3 py-2 text-left text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset",
                  loc === locale ? "bg-primary/10 text-primary-800" : "text-gray-800 hover:bg-gray-50",
                )}
                onClick={() => selectLocale(loc)}
              >
                {LABELS[loc] ?? loc.toUpperCase()}
              </button>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}

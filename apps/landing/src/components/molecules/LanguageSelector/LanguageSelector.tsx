"use client";

import { ChevronDown } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { routing, usePathname, useRouter } from "@/i18n/routing";
import { cn } from "@/lib/utils/cn";
import { useEffect, useRef, useState } from "react";

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
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function onDocClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("click", onDocClick);
    return () => document.removeEventListener("click", onDocClick);
  }, []);

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        className="flex items-center gap-2 rounded-full border border-gray-200/90 bg-white/80 px-3 py-1.5 text-[0.8125rem] font-semibold tracking-wide text-gray-800 shadow-sm transition-colors hover:border-gray-300 hover:bg-gray-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
        aria-label={`${t("language")}: ${LABELS[locale] ?? locale}`}
        aria-haspopup="listbox"
        aria-expanded={open}
        onClick={() => setOpen((o) => !o)}
      >
        <span className="tabular-nums">{LABELS[locale] ?? locale.toUpperCase()}</span>
        <ChevronDown className="h-3.5 w-3.5 text-gray-500" strokeWidth={2} aria-hidden />
      </button>
      {open ? (
        <ul
          className="absolute right-0 z-50 mt-1 min-w-[5.5rem] rounded-xl border border-gray-200/90 bg-white py-1 shadow-lg ring-1 ring-black/[0.04]"
          role="listbox"
        >
          {routing.locales.map((loc) => (
            <li key={loc} role="option" aria-selected={loc === locale}>
              <button
                type="button"
                className={cn(
                  "flex w-full items-center px-3 py-2 text-left text-sm font-medium transition-colors",
                  loc === locale ? "bg-primary/10 text-primary-700" : "text-gray-800 hover:bg-gray-50",
                )}
                onClick={() => {
                  setOpen(false);
                  router.replace(pathname, { locale: loc });
                }}
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

"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { ChevronUp } from "lucide-react";
import { scrollToTopSmooth } from "@/lib/utils/smooth-scroll";
import { cn } from "@/lib/utils/cn";

const SHOW_AFTER_PX = 400;

export function ScrollToTopButton() {
  const t = useTranslations("common");
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const onScroll = () => setVisible(window.scrollY > SHOW_AFTER_PX);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <button
      type="button"
      onClick={() => scrollToTopSmooth()}
      aria-label={t("scrollToTop")}
      className={cn(
        "fixed bottom-5 right-5 z-40 flex h-11 w-11 items-center justify-center rounded-full border border-gray-200/90 bg-white/95 text-gray-700 shadow-lg shadow-gray-900/[0.08] ring-1 ring-black/[0.04] backdrop-blur-sm transition-[opacity,transform,visibility] duration-300 ease-out motion-safe:hover:border-primary/25 motion-safe:hover:bg-primary/[0.06] motion-safe:hover:text-primary motion-safe:hover:shadow-primary/15 md:bottom-8 md:right-8",
        visible
          ? "pointer-events-auto translate-y-0 opacity-100"
          : "pointer-events-none translate-y-3 opacity-0",
      )}
    >
      <ChevronUp className="h-5 w-5" strokeWidth={2} aria-hidden />
    </button>
  );
}

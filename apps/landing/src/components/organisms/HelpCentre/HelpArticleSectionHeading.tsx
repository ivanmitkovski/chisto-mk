"use client";

import { useState } from "react";
import { Link2, Check } from "lucide-react";
import { cn } from "@/lib/utils/cn";

export function HelpArticleSectionHeading({
  sectionId,
  title,
  copyLabel,
  copiedLabel,
}: {
  sectionId: string;
  title: string;
  /** Short phrase for `aria-label` (icon only, no visible text). */
  copyLabel: string;
  /** Announced when copy succeeds (e.g. `aria-label` while copied). */
  copiedLabel: string;
}) {
  const [copied, setCopied] = useState(false);

  async function onCopy() {
    if (typeof window === "undefined") return;
    const { origin, pathname } = window.location;
    const url = `${origin}${pathname}#${sectionId}`;
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      setCopied(false);
    }
  }

  return (
    <div className="mb-4 flex flex-wrap items-start gap-x-2 gap-y-2 md:mb-5 md:gap-x-2.5">
      <h2 className="min-w-0 flex-1 text-balance text-xl font-bold tracking-tight text-gray-900 md:text-2xl">{title}</h2>
      <button
        type="button"
        onClick={onCopy}
        aria-label={copied ? copiedLabel : copyLabel}
        className={cn(
          "inline-flex min-h-11 min-w-11 shrink-0 items-center justify-center self-start rounded-lg text-gray-500 transition-colors",
          "mt-0.5 md:mt-1",
          "hover:bg-gray-100 hover:text-gray-800",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2",
          copied && "text-emerald-600 hover:text-emerald-700",
        )}
      >
        {copied ? (
          <Check className="h-4 w-4" strokeWidth={2.25} aria-hidden />
        ) : (
          <Link2 className="h-4 w-4" strokeWidth={2} aria-hidden />
        )}
      </button>
    </div>
  );
}

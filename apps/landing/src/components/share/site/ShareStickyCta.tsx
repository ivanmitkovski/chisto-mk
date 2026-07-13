"use client";

import Link from "next/link";
import { buttonVariants } from "@/components/atoms/Button";
import { trackMarketingEvent } from "@/lib/analytics/track-marketing";
import { cn } from "@/lib/utils/cn";

type ShareStickyCtaProps = {
  openInAppHref: string;
  openInAppLabel: string;
  getAppHref: string;
  getAppLabel: string;
  exploreHref: string;
  exploreLabel: string;
};

export function ShareStickyCta({
  openInAppHref,
  openInAppLabel,
  getAppHref,
  getAppLabel,
  exploreHref,
  exploreLabel,
}: ShareStickyCtaProps) {
  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-0 z-40">
      <div className="pointer-events-auto mx-auto max-w-2xl border-t border-divider/80 bg-white/95 px-4 pb-[max(1rem,env(safe-area-inset-bottom))] pt-3 shadow-[0_-8px_30px_rgba(0,0,0,0.06)] backdrop-blur-md">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
          <Link
            href={openInAppHref}
            className={cn(
              buttonVariants({ variant: "primary", size: "md" }),
              "min-h-14 w-full flex-1 text-[17px] font-semibold sm:w-auto",
            )}
          >
            {openInAppLabel}
          </Link>
          <a
            href={getAppHref}
            onClick={() => {
              trackMarketingEvent("download_cta_click", { source: "share_get_app" });
            }}
            className={cn(
              buttonVariants({ variant: "outline", size: "md" }),
              "min-h-14 w-full flex-1 text-[17px] font-semibold sm:w-auto",
            )}
          >
            {getAppLabel}
          </a>
        </div>
        <p className="mt-3 text-center text-sm text-ink-muted">
          <a
            href={exploreHref}
            className="font-medium text-primary-text underline-offset-2 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          >
            {exploreLabel}
          </a>
        </p>
      </div>
    </div>
  );
}

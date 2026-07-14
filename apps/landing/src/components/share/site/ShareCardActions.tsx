"use client";

import { OpenInAppLink } from "@/components/app-handoff/OpenInAppLink";
import { buttonVariants } from "@/components/atoms/Button";
import { trackMarketingEvent } from "@/lib/analytics/track-marketing";
import { cn } from "@/lib/utils/cn";

type ShareCardActionsProps = {
  openInAppHref: string;
  openInAppLabel: string;
  getAppHref: string;
  getAppLabel: string;
  exploreHref: string;
  exploreLabel: string;
};

/** In-card CTA block (not viewport-fixed) — matches event share shell pattern. */
export function ShareCardActions({
  openInAppHref,
  openInAppLabel,
  getAppHref,
  getAppLabel,
  exploreHref,
  exploreLabel,
}: ShareCardActionsProps) {
  return (
    <div className="border-t border-divider pt-5">
      <div className="flex flex-col gap-2.5 sm:flex-row sm:items-stretch">
        <OpenInAppLink
          href={openInAppHref}
          className={cn(
            buttonVariants({ variant: "primary", size: "md" }),
            "min-h-14 w-full flex-1 justify-center text-[17px] font-semibold",
          )}
        >
          {openInAppLabel}
        </OpenInAppLink>
        <a
          href={getAppHref}
          onClick={() => {
            trackMarketingEvent("download_cta_click", { source: "share_get_app" });
          }}
          className={cn(
            buttonVariants({ variant: "outline", size: "md" }),
            "min-h-14 w-full flex-1 justify-center text-[17px] font-semibold",
          )}
        >
          {getAppLabel}
        </a>
      </div>
      <p className="mt-4 text-center text-sm text-ink-muted">
        <a
          href={exploreHref}
          className="font-medium text-primary-text underline-offset-2 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
        >
          {exploreLabel}
        </a>
      </p>
    </div>
  );
}

"use client";

import { trackMarketingEvent } from "@/lib/analytics/track-marketing";
import { buttonVariants } from "@/components/atoms/Button";
import { cn } from "@/lib/utils/cn";

type ShareActionLinkProps = {
  href: string;
  label: string;
  variant?: "primary" | "outline";
  analyticsSource?: string;
};

export function ShareActionLink({
  href,
  label,
  variant = "outline",
  analyticsSource = "share_shell",
}: ShareActionLinkProps) {
  return (
    <a
      href={href}
      onClick={() => {
        if (analyticsSource) {
          trackMarketingEvent("download_cta_click", { source: analyticsSource });
        }
      }}
      className={cn(buttonVariants({ variant: variant === "primary" ? "primary" : "outline", size: "md" }))}
    >
      {label}
    </a>
  );
}

"use client";

import { FloatingPhone } from "@/components/molecules/FloatingPhone";
import { PhoneMockup } from "@/components/molecules/PhoneMockup";
import { PhoneScreen } from "@/components/molecules/PhoneDemoScreens";
import { MARKETING_PHONE_SCREENSHOTS } from "@/lib/app-screenshots";
import { cn } from "@/lib/utils/cn";

interface MarketingPhoneRowProps {
  priorityIndex?: number;
  className?: string;
  sideClassName?: string;
  centerClassName?: string;
  centerShadow?: string;
  /** Wrap each phone in a scroll-reveal float animation (CTA section). */
  floating?: boolean;
}

export function MarketingPhoneRow({
  priorityIndex = 1,
  className,
  sideClassName = "w-[13.5rem] shrink-0 origin-bottom scale-[0.94] lg:w-60",
  centerClassName = "z-10 w-[min(100%,17.5rem)] shrink-0 sm:w-60 lg:w-72",
  centerShadow = "shadow-[var(--shadow-phone-lg)]",
  floating = false,
}: MarketingPhoneRowProps) {
  return (
    <div
      className={cn(
        "flex w-full items-end justify-center gap-3 overflow-visible px-2 sm:gap-5 md:gap-7 lg:gap-8",
        className,
      )}
    >
      {MARKETING_PHONE_SCREENSHOTS.map((screenshotId, index) => {
        const isCenter = index === 1;
        const shellClassName = isCenter ? centerClassName : sideClassName;
        const phone = (
          <PhoneMockup {...(isCenter ? { className: centerShadow } : {})}>
            <PhoneScreen
              variant={screenshotId}
              {...(index === priorityIndex ? { priority: true } : {})}
            />
          </PhoneMockup>
        );

        if (floating) {
          return (
            <FloatingPhone
              key={screenshotId}
              className={shellClassName}
              delay={index * 0.12}
            >
              {phone}
            </FloatingPhone>
          );
        }

        return (
          <div key={screenshotId} className={shellClassName}>
            {phone}
          </div>
        );
      })}
    </div>
  );
}

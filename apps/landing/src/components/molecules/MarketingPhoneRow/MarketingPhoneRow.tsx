"use client";

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
}

export function MarketingPhoneRow({
  priorityIndex = 1,
  className,
  sideClassName = "w-[13.5rem] shrink-0 origin-bottom scale-[0.94] lg:w-60",
  centerClassName = "z-10 w-[min(100%,17.5rem)] shrink-0 sm:w-60 lg:w-72",
  centerShadow = "shadow-[var(--shadow-phone-lg)]",
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

        return (
          <div
            key={screenshotId}
            className={isCenter ? centerClassName : sideClassName}
          >
            <PhoneMockup {...(isCenter ? { className: centerShadow } : {})}>
              <PhoneScreen
                variant={screenshotId}
                {...(index === priorityIndex ? { priority: true } : {})}
              />
            </PhoneMockup>
          </div>
        );
      })}
    </div>
  );
}

"use client";

import {
  HERO_PHONE_SCREENSHOTS,
  type AppScreenshotId,
} from "@/lib/app-screenshots";
import { PhoneScreenshot } from "@/components/molecules/PhoneScreenshot";

export const HERO_PHONE_VARIANTS = HERO_PHONE_SCREENSHOTS;
export type HeroPhoneVariant = AppScreenshotId;

export function PhoneScreen({
  variant,
  priority,
}: {
  variant: HeroPhoneVariant;
  priority?: boolean;
}) {
  return (
    <PhoneScreenshot
      screenshotId={variant}
      {...(priority === true ? { priority: true } : {})}
    />
  );
}

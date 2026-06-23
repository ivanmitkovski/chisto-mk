"use client";

import Image from "next/image";
import { useTranslations } from "next-intl";
import {
  APP_SCREENSHOTS,
  SCREENSHOT_BLUR_DATA_URL,
  type AppScreenshotId,
} from "@/lib/app-screenshots";
import { cn } from "@/lib/utils/cn";

interface PhoneScreenshotProps {
  screenshotId: AppScreenshotId;
  priority?: boolean;
  className?: string;
}

export function PhoneScreenshot({
  screenshotId,
  priority = false,
  className,
}: PhoneScreenshotProps) {
  const t = useTranslations("screenshots");
  const { src, altKey } = APP_SCREENSHOTS[screenshotId];

  return (
    <div
      className={cn(
        "relative aspect-[9/19.5] overflow-hidden bg-white",
        className,
      )}
    >
      <Image
        src={src}
        alt={t(altKey)}
        fill
        priority={priority}
        placeholder="blur"
        blurDataURL={SCREENSHOT_BLUR_DATA_URL}
        sizes="(max-width: 768px) 280px, 320px"
        className="object-cover object-top"
      />
    </div>
  );
}

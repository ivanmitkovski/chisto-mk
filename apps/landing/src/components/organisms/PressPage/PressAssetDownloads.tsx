"use client";

import { useTranslations } from "next-intl";
import { trackMarketingEvent } from "@/lib/analytics/track-marketing";

const SCREENSHOTS = [
  { href: "/screenshots/ios/welcome.jpg", key: "welcome" as const },
  { href: "/screenshots/ios/feed.jpg", key: "feed" as const },
  { href: "/screenshots/ios/map.jpg", key: "map" as const },
];

function trackAsset(asset: string) {
  trackMarketingEvent("press_asset_download", { asset });
}

export function PressAssetDownloads() {
  const t = useTranslations("pressPage");

  return (
    <div className="space-y-5">
      <div className="rounded-2xl border border-gray-200/90 bg-white/70 p-6 shadow-sm backdrop-blur-sm">
        <p className="font-semibold text-gray-900">{t("logoTitle")}</p>
        <p className="mt-2 text-sm text-gray-600">{t("logoBody")}</p>
        <a
          href="/brand/chisto-mark.svg"
          download
          onClick={() => trackAsset("logo-svg")}
          className="mt-4 inline-flex text-sm font-semibold text-primary underline-offset-4 hover:underline"
        >
          {t("downloadMark")}
        </a>
      </div>
      <div className="rounded-2xl border border-gray-200/90 bg-white/70 p-6 shadow-sm backdrop-blur-sm">
        <p className="font-semibold text-gray-900">{t("screenshotsTitle")}</p>
        <ul className="mt-4 space-y-2">
          {SCREENSHOTS.map((shot) => (
            <li key={shot.key}>
              <a
                href={shot.href}
                download
                onClick={() => trackAsset(`screenshot-${shot.key}`)}
                className="text-sm font-semibold text-primary underline-offset-4 hover:underline"
              >
                {t(`screenshot.${shot.key}`)}
              </a>
            </li>
          ))}
        </ul>
      </div>
      <div className="rounded-2xl border border-gray-200/90 bg-white/70 p-6 shadow-sm backdrop-blur-sm">
        <p className="font-semibold text-gray-900">{t("pressKitTitle")}</p>
        <p className="mt-2 text-sm text-gray-600">{t("pressKitBody")}</p>
        <a
          href="/press/chisto-press-kit.zip"
          download
          onClick={() => trackAsset("press-kit-zip")}
          className="mt-4 inline-flex text-sm font-semibold text-primary underline-offset-4 hover:underline"
        >
          {t("downloadPressKit")}
        </a>
      </div>
    </div>
  );
}

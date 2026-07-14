"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Image from "next/image";
import { buttonVariants } from "@/components/atoms/Button";
import { trackMarketingEvent } from "@/lib/analytics/track-marketing";
import {
  httpsAppUrlToAndroidIntent,
  httpsAppUrlToCustomScheme,
} from "@/lib/app-deep-link";
import { getAppStoreUrl, getGooglePlayUrl } from "@/lib/store-links";
import { cn } from "@/lib/utils/cn";

export type AppHandoffCopy = {
  title: string;
  body: string;
  openApp: string;
  explore: string;
  opening: string;
};

type AppOpenHandoffProps = {
  /** Absolute https universal-link URL (`https://…/app/…`). */
  httpsUrl: string;
  exploreHref: string;
  copy: AppHandoffCopy;
};

function isAndroidUa(ua: string): boolean {
  return /Android/i.test(ua);
}

function tryOpenApp(httpsUrl: string): void {
  const ua = typeof navigator !== "undefined" ? navigator.userAgent : "";
  const custom = httpsAppUrlToCustomScheme(httpsUrl);
  if (isAndroidUa(ua)) {
    const play = getGooglePlayUrl() ?? httpsUrl;
    const intent = httpsAppUrlToAndroidIntent(httpsUrl, play);
    window.location.href = intent ?? custom ?? httpsUrl;
    return;
  }
  if (custom) {
    window.location.href = custom;
  }
}

export function AppOpenHandoff({ httpsUrl, exploreHref, copy }: AppOpenHandoffProps) {
  const [showFallback, setShowFallback] = useState(false);
  const appStoreUrl = useMemo(() => getAppStoreUrl(), []);
  const playUrl = useMemo(() => getGooglePlayUrl(), []);

  useEffect(() => {
    trackMarketingEvent("app_handoff_view", { path: new URL(httpsUrl).pathname });
    tryOpenApp(httpsUrl);
    const timer = window.setTimeout(() => {
      if (document.visibilityState === "visible") {
        setShowFallback(true);
      }
    }, 1400);
    const onVis = () => {
      if (document.visibilityState === "hidden") {
        window.clearTimeout(timer);
      }
    };
    document.addEventListener("visibilitychange", onVis);
    return () => {
      window.clearTimeout(timer);
      document.removeEventListener("visibilitychange", onVis);
    };
  }, [httpsUrl]);

  const onOpenClick = useCallback(() => {
    trackMarketingEvent("open_in_app_click", { source: "app_handoff" });
    tryOpenApp(httpsUrl);
    window.setTimeout(() => {
      if (document.visibilityState === "visible") {
        setShowFallback(true);
      }
    }, 1600);
  }, [httpsUrl]);

  return (
    <main className="min-h-dvh bg-[#F4F5F7] px-4 py-10 font-sans text-[#121212]">
      <div className="mx-auto max-w-lg">
        <div className="mb-8 flex items-center gap-2">
          <Image
            src="/brand/chisto-mark.svg"
            alt=""
            width={28}
            height={32}
            className="h-7 w-auto"
            unoptimized
          />
          <span className="text-lg font-bold tracking-tight text-[#121212]">
            Chisto<span className="brand-logotype font-medium text-primary">.mk</span>
          </span>
        </div>

        <div className="rounded-[24px] border border-[#E5E7ED]/90 bg-white p-6 shadow-[var(--shadow-card)] ring-1 ring-black/[0.04] md:p-8">
          <p className="text-xs font-semibold uppercase tracking-wider text-[#7A7A7A]">Chisto.mk</p>
          <h1 className="mt-2 text-2xl font-bold tracking-tight text-[#121212]">
            {showFallback ? copy.title : copy.opening}
          </h1>
          <p className="mt-3 text-sm leading-relaxed text-[#4C4C4C]">{copy.body}</p>

          <div className="mt-8 flex flex-col gap-2.5">
            <button
              type="button"
              onClick={onOpenClick}
              className={cn(
                buttonVariants({ variant: "primary", size: "md" }),
                "min-h-14 w-full justify-center text-[17px] font-semibold",
              )}
            >
              {copy.openApp}
            </button>

            {showFallback ? (
              <>
                {appStoreUrl ? (
                  <a
                    href={appStoreUrl}
                    onClick={() =>
                      trackMarketingEvent("download_cta_click", { source: "app_handoff_ios" })
                    }
                    className={cn(
                      buttonVariants({ variant: "outline", size: "md" }),
                      "min-h-14 w-full justify-center text-[17px] font-semibold",
                    )}
                  >
                    App Store
                  </a>
                ) : null}
                {playUrl ? (
                  <a
                    href={playUrl}
                    onClick={() =>
                      trackMarketingEvent("download_cta_click", { source: "app_handoff_android" })
                    }
                    className={cn(
                      buttonVariants({ variant: "outline", size: "md" }),
                      "min-h-14 w-full justify-center text-[17px] font-semibold",
                    )}
                  >
                    Google Play
                  </a>
                ) : null}
                <a
                  href={exploreHref}
                  className={cn(
                    buttonVariants({ variant: "ghost", size: "md" }),
                    "min-h-12 w-full justify-center text-[15px] font-semibold text-ink-muted",
                  )}
                >
                  {copy.explore}
                </a>
              </>
            ) : null}
          </div>
        </div>
      </div>
    </main>
  );
}

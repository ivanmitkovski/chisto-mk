"use client";

import { useCallback, useRef, type MouseEvent, type ReactNode } from "react";
import { trackMarketingEvent } from "@/lib/analytics/track-marketing";
import {
  httpsAppUrlToAndroidIntent,
  httpsAppUrlToCustomScheme,
  resolveAppHttpsUrl,
} from "@/lib/app-deep-link";
import { getAppStoreUrl, getGooglePlayUrl } from "@/lib/store-links";

type OpenInAppLinkProps = {
  href: string;
  className?: string;
  children: ReactNode;
  analyticsSource?: string;
};

function isAndroidUa(ua: string): boolean {
  return /Android/i.test(ua);
}

/**
 * Opens the native app via custom scheme / Android Intent on a real user gesture
 * (required for same-domain Safari, where Universal Links do not re-open the app).
 * Falls back to the https `/app/...` handoff page, then stores.
 */
export function OpenInAppLink({
  href,
  className,
  children,
  analyticsSource = "share_open_in_app",
}: OpenInAppLinkProps) {
  const fallbackTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const onClick = useCallback(
    (event: MouseEvent<HTMLAnchorElement>) => {
      if (event.defaultPrevented) return;
      if (event.button !== 0) return;
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;

      event.preventDefault();
      trackMarketingEvent("open_in_app_click", { source: analyticsSource });

      const origin = window.location.origin;
      const httpsUrl = resolveAppHttpsUrl(href, origin);
      const custom = httpsAppUrlToCustomScheme(httpsUrl);
      const ua = navigator.userAgent;

      if (fallbackTimer.current) {
        clearTimeout(fallbackTimer.current);
      }

      if (isAndroidUa(ua)) {
        const play = getGooglePlayUrl() ?? httpsUrl;
        const intent = httpsAppUrlToAndroidIntent(httpsUrl, play);
        window.location.href = intent ?? custom ?? httpsUrl;
        return;
      }

      if (custom) {
        window.location.href = custom;
      }

      // If the app did not take focus, land on the handoff page (stores + retry).
      fallbackTimer.current = setTimeout(() => {
        if (document.visibilityState === "hidden") return;
        const store = /iPhone|iPad|iPod/i.test(ua) ? getAppStoreUrl() : null;
        window.location.href = custom ? httpsUrl : (store ?? httpsUrl);
      }, 1600);
    },
    [analyticsSource, href],
  );

  return (
    <a href={href} className={className} onClick={onClick} rel="noopener">
      {children}
    </a>
  );
}

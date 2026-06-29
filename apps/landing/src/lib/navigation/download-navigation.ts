"use client";

import { useCallback, type MouseEvent } from "react";
import { usePathname, useRouter } from "@/i18n/routing";
import {
  DOWNLOAD_HASH_HREF,
  isOnHomePage,
  navigateToDownloadFromPath,
  scrollToDownloadOnHome,
} from "./download-navigation.shared";

export {
  DOWNLOAD_HASH_HREF,
  isOnHomePage,
  isMobileViewport,
  navigateToDownloadFromPath,
  scrollToDownloadFromHashNavigation,
  scrollToDownloadOnHome,
} from "./download-navigation.shared";

export function useDownloadNavigation() {
  const pathname = usePathname();
  const router = useRouter();

  const navigateToDownload = useCallback(() => {
    navigateToDownloadFromPath(pathname, router);
  }, [pathname, router]);

  const handleDownloadLinkClick = useCallback(
    (e: MouseEvent<HTMLAnchorElement>) => {
      if (!isOnHomePage(pathname)) return;
      e.preventDefault();
      scrollToDownloadOnHome();
    },
    [pathname],
  );

  return {
    downloadHref: DOWNLOAD_HASH_HREF,
    pathname,
    router,
    navigateToDownload,
    handleDownloadLinkClick,
    scrollToDownloadOnHome,
  };
}

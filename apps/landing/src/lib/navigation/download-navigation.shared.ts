import {
  DOWNLOAD_SECTION_ID,
  scheduleScrollToDownloadSection,
  scrollToDownloadSection,
} from "@/lib/utils/smooth-scroll";

export const DOWNLOAD_HASH_HREF = `/#${DOWNLOAD_SECTION_ID}`;

export function isOnHomePage(pathname: string): boolean {
  return pathname === "/";
}

export function isMobileViewport(): boolean {
  if (typeof window === "undefined") return false;
  return window.matchMedia("(max-width: 767px)").matches;
}

export function scrollToDownloadOnHome(instant?: boolean): void {
  const useInstant = instant ?? isMobileViewport();
  scheduleScrollToDownloadSection(0, {
    behavior: useInstant ? "instant" : "smooth",
  });
}

export function navigateToDownloadFromPath(
  pathname: string,
  router: { push: (href: string) => void },
): void {
  if (!isOnHomePage(pathname)) {
    router.push(DOWNLOAD_HASH_HREF);
    return;
  }
  scrollToDownloadOnHome();
}

/** Imperative scroll used by Hero on user-initiated hash navigation only. */
export function scrollToDownloadFromHashNavigation(): void {
  scrollToDownloadSection({ behavior: isMobileViewport() ? "instant" : "smooth" });
}

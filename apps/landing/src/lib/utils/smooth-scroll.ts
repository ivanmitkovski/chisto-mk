/**
 * Scroll helpers for the marketing site.
 *
 * Download flow: badges live at the hero top, so `scrollToDownloadSection` scrolls to
 * `top: 0` (not an element offset). `getScrollPaddingTopPx` is for generic in-page
 * anchors that respect sticky header + `scroll-padding-top` in globals.css.
 */
import type { MouseEvent } from "react";

export const DOWNLOAD_SECTION_ID = "download";

export function prefersReducedMotion(): boolean {
  if (typeof window === "undefined") return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

function measureHeaderHeight(): number {
  const header = document.querySelector("header");
  if (header) {
    return header.getBoundingClientRect().height;
  }
  return window.matchMedia("(min-width: 768px)").matches ? 80 : 68;
}

/** Offset used when scrolling to in-page anchors (sticky header + breathing room). */
export function getScrollPaddingTopPx(): number {
  if (typeof window === "undefined") return 0;

  const root = document.documentElement;
  const fromStyle = parseFloat(getComputedStyle(root).scrollPaddingTop);
  if (!Number.isNaN(fromStyle) && fromStyle > 0) {
    return fromStyle;
  }

  const cssVar = getComputedStyle(root).getPropertyValue("--scroll-margin-top").trim();
  if (cssVar) {
    const probe = document.createElement("div");
    probe.style.position = "absolute";
    probe.style.visibility = "hidden";
    probe.style.height = cssVar;
    document.body.appendChild(probe);
    const parsed = probe.getBoundingClientRect().height;
    probe.remove();
    if (parsed > 0) return parsed;
  }

  return measureHeaderHeight() + 24;
}

export type ScrollToDownloadOptions = {
  /** Sync the URL hash (default true). */
  updateHash?: boolean;
  /** Scroll behavior override; defaults to reduced-motion aware smooth. */
  behavior?: ScrollBehavior;
};

function resolveScrollBehavior(override?: ScrollBehavior): ScrollBehavior {
  if (override) return override;
  return prefersReducedMotion() ? "instant" : "smooth";
}

/**
 * Scrolls to the hero top so the download badges sit in view below the sticky header.
 */
export function scrollToDownloadSection(options: ScrollToDownloadOptions = {}): boolean {
  if (typeof window === "undefined") return false;

  const { updateHash = true, behavior } = options;
  const target = document.getElementById(DOWNLOAD_SECTION_ID);
  if (!target) return false;

  window.scrollTo({
    top: 0,
    behavior: resolveScrollBehavior(behavior),
  });

  if (updateHash) {
    const hash = `#${DOWNLOAD_SECTION_ID}`;
    if (window.location.hash !== hash) {
      history.replaceState(
        history.state,
        "",
        `${window.location.pathname}${window.location.search}${hash}`,
      );
    }
  }

  return true;
}

export type ScheduleScrollToDownloadOptions = Pick<ScrollToDownloadOptions, "behavior">;

/** Defer scroll until layout settles (e.g. after closing the mobile nav drawer). */
export function scheduleScrollToDownloadSection(
  delayMs = 0,
  options: ScheduleScrollToDownloadOptions = {},
): void {
  if (typeof window === "undefined") return;

  const run = () => scrollToDownloadSection(options);

  if (delayMs > 0) {
    window.setTimeout(run, delayMs);
    return;
  }

  requestAnimationFrame(() => {
    requestAnimationFrame(run);
  });
}

/** Smooth scroll to top; respects reduced motion. */
export function scrollToTopSmooth(): void {
  if (typeof window === "undefined") return;
  window.scrollTo({
    top: 0,
    behavior: prefersReducedMotion() ? "instant" : "smooth",
  });
}

/**
 * When already on the home page, Home/logo clicks should scroll to top smoothly
 * instead of reloading the same route.
 */
export function handleHomeNavigationClick(
  e: MouseEvent<HTMLAnchorElement>,
  pathname: string,
  href: string,
): void {
  if (href !== "/" || pathname !== "/") return;
  e.preventDefault();
  scrollToTopSmooth();
}

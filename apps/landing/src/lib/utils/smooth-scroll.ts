import type { MouseEvent } from "react";

export function prefersReducedMotion(): boolean {
  if (typeof window === "undefined") return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
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

/** Store-submission launch visibility — flip to `true` when pages are ready to ship. */
export const LAUNCH_PAGE_VISIBILITY = {
  about: true,
  news: true,
  press: true,
} as const;

export type HiddenLaunchPage = keyof typeof LAUNCH_PAGE_VISIBILITY;

export function isLaunchPageVisible(page: HiddenLaunchPage): boolean {
  return LAUNCH_PAGE_VISIBILITY[page];
}

/**
 * Primary header navigation — left-to-right priority:
 * Home → About → News → Help → Contact (support before contact is standard).
 * Press stays in the footer only (media kit, not a consumer journey).
 */
export const MARKETING_NAV_ITEMS = [
  { href: "/", key: "home" as const },
  { href: "/about", key: "about" as const, hiddenPage: "about" as const },
  { href: "/news", key: "news" as const, hiddenPage: "news" as const },
  { href: "/help", key: "help" as const },
  { href: "/contact", key: "contact" as const },
] as const;

export function visibleMarketingNavItems() {
  return MARKETING_NAV_ITEMS.filter((item) => {
    if (!("hiddenPage" in item)) return true;
    return isLaunchPageVisible(item.hiddenPage);
  });
}

export const SITEMAP_PATHS = [
  "",
  "/contact",
  "/terms",
  "/privacy",
  "/cookies",
  "/data",
  "/help",
  ...(isLaunchPageVisible("about") ? ["/about"] : []),
  ...(isLaunchPageVisible("news") ? ["/news"] : []),
  ...(isLaunchPageVisible("press") ? ["/press"] : []),
] as const;

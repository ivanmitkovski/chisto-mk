/** Store-submission launch visibility — flip to `true` when pages are ready to ship. */
export const LAUNCH_PAGE_VISIBILITY = {
  about: false,
  news: false,
  press: false,
} as const;

/** Home page sections — flip to `true` when real data is available. */
export const LAUNCH_HOME_SECTIONS = {
  stats: false,
} as const;

export type HiddenLaunchPage = keyof typeof LAUNCH_PAGE_VISIBILITY;
export type HiddenLaunchHomeSection = keyof typeof LAUNCH_HOME_SECTIONS;

export function isLaunchPageVisible(page: HiddenLaunchPage): boolean {
  return LAUNCH_PAGE_VISIBILITY[page];
}

export function isLaunchHomeSectionVisible(section: HiddenLaunchHomeSection): boolean {
  return LAUNCH_HOME_SECTIONS[section];
}

export const MARKETING_NAV_ITEMS = [
  { href: "/", key: "home" as const },
  { href: "/about", key: "about" as const, hiddenPage: "about" as const },
  { href: "/news", key: "news" as const, hiddenPage: "news" as const },
  { href: "/press", key: "press" as const, hiddenPage: "press" as const },
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

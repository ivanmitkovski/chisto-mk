export type AppScreenshotId =
  | "welcome"
  | "signIn"
  | "map"
  | "feed"
  | "siteDetail";

export const APP_SCREENSHOTS: Record<
  AppScreenshotId,
  { src: string; altKey: string }
> = {
  welcome: {
    src: "/screenshots/ios/welcome.jpg",
    altKey: "welcomeAlt",
  },
  signIn: {
    src: "/screenshots/ios/sign-in.jpg",
    altKey: "signInAlt",
  },
  map: {
    src: "/screenshots/ios/map.jpg",
    altKey: "mapAlt",
  },
  feed: {
    src: "/screenshots/ios/feed.jpg",
    altKey: "feedAlt",
  },
  siteDetail: {
    src: "/screenshots/ios/site-detail.jpg",
    altKey: "siteDetailAlt",
  },
};

export const HERO_PHONE_SCREENSHOTS: AppScreenshotId[] = [
  "signIn",
  "welcome",
  "feed",
  "map",
  "siteDetail",
];

export const HERO_PHONE_DECK_LABEL_KEYS: Record<
  AppScreenshotId,
  | "phoneDeckSlideLogin"
  | "phoneDeckSlideWelcome"
  | "phoneDeckSlideFeed"
  | "phoneDeckSlideMap"
  | "phoneDeckSlideSiteDetail"
> = {
  signIn: "phoneDeckSlideLogin",
  welcome: "phoneDeckSlideWelcome",
  feed: "phoneDeckSlideFeed",
  map: "phoneDeckSlideMap",
  siteDetail: "phoneDeckSlideSiteDetail",
};

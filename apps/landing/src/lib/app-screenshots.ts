export type AppScreenshotId =
  | "welcome"
  | "signIn"
  | "map"
  | "feed"
  | "siteDetail"
  | "events";

/** Shared neutral blur for screenshot placeholders (10×10 gray). */
export const SCREENSHOT_BLUR_DATA_URL =
  "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAIAAoDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAb/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=";

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
  events: {
    src: "/screenshots/ios/events.jpg",
    altKey: "eventsAlt",
  },
};

/** Mobile hero swipe deck: same welcome → feed → map arc as desktop. */
export const HERO_PHONE_SCREENSHOTS: AppScreenshotId[] = [
  "welcome",
  "feed",
  "map",
];

/** Hero desktop + CTA: welcome → feed → map story arc. */
export const MARKETING_PHONE_SCREENSHOTS: AppScreenshotId[] = [
  "welcome",
  "feed",
  "map",
];

export const HERO_PHONE_DECK_LABEL_KEYS: Record<
  AppScreenshotId,
  | "phoneDeckSlideWelcome"
  | "phoneDeckSlideFeed"
  | "phoneDeckSlideMap"
  | "phoneDeckSlideLogin"
  | "phoneDeckSlideSiteDetail"
  | "phoneDeckSlideEvents"
> = {
  welcome: "phoneDeckSlideWelcome",
  feed: "phoneDeckSlideFeed",
  map: "phoneDeckSlideMap",
  signIn: "phoneDeckSlideLogin",
  siteDetail: "phoneDeckSlideSiteDetail",
  events: "phoneDeckSlideEvents",
};

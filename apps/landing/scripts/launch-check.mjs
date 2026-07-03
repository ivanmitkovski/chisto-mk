#!/usr/bin/env node
/**
 * Pre-launch sanity checks for the landing app.
 * Run: pnpm --filter @chisto/landing launch:check
 */
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
let failed = false;

function fail(msg) {
  console.error(`launch-check: ${msg}`);
  failed = true;
}

function pass(msg) {
  console.log(`launch-check: ${msg}`);
}

const launchPath = join(root, "src/config/launch.ts");
const launchSrc = readFileSync(launchPath, "utf8");

const appStore =
  process.env.NEXT_PUBLIC_APP_STORE_URL?.trim() ||
  "https://apps.apple.com/mk/app/chisto-mk/id6771892086";
if (!appStore.startsWith("https://")) {
  fail("App Store URL must be HTTPS");
} else if (!appStore.includes("/mk/app/")) {
  fail("App Store URL should use the Macedonia storefront (/mk/app/…) for this listing");
} else {
  pass("App Store URL configured");
}

const googlePlay =
  process.env.NEXT_PUBLIC_GOOGLE_PLAY_URL?.trim() ||
  "https://play.google.com/store/apps/details?id=mk.chisto.app";
if (!googlePlay.startsWith("https://")) {
  fail("Google Play URL must be HTTPS");
} else if (!googlePlay.includes("id=mk.chisto.app")) {
  fail("Google Play URL should reference package mk.chisto.app");
} else {
  pass("Google Play URL configured");
}

const screenshotDir = join(root, "public/screenshots/ios");
for (const file of ["welcome.jpg", "feed.jpg", "map.jpg", "site-detail.jpg", "sign-in.jpg", "events.jpg"]) {
  if (!existsSync(join(screenshotDir, file))) {
    fail(`missing screenshot: public/screenshots/ios/${file}`);
  }
}

if (!existsSync(join(root, "public/press/chisto-press-kit.zip"))) {
  fail("missing press kit: public/press/chisto-press-kit.zip");
}

if (launchSrc.includes("LAUNCH_HOME_SECTIONS")) {
  console.warn("launch-check: remove stale LAUNCH_HOME_SECTIONS reference from launch.ts");
}
for (const page of ["about: false", "news: false", "press: false"]) {
  if (launchSrc.includes(page)) {
    console.warn(`launch-check: LAUNCH_PAGE_VISIBILITY.${page.split(":")[0]} is still false`);
  }
}

const resendKeys = ["RESEND_API_KEY", "RESEND_FROM_EMAIL", "RESEND_NOTIFY_TO"];
const missingResend = resendKeys.filter((k) => !process.env[k]?.trim());
if (missingResend.length > 0) {
  console.warn(`launch-check: missing Resend env (forms will fail): ${missingResend.join(", ")}`);
}

if (failed) {
  process.exit(1);
}
console.log("launch-check: OK");

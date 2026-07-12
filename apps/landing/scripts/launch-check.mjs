#!/usr/bin/env node
/**
 * Pre-launch sanity checks for the landing app.
 * Run: pnpm --filter @chisto/landing launch:check
 *
 * Optional strict analytics probe:
 *   VERIFY_ANALYTICS_URL=https://www.chisto.mk pnpm launch:check
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

function warn(msg) {
  console.warn(`launch-check: ${msg}`);
}

function isJsContentType(type) {
  const t = (type ?? "").toLowerCase();
  return t.includes("javascript") || t.includes("ecmascript");
}

async function probeInsightsScript(baseUrl, { strict }) {
  const scriptUrl = `${baseUrl.replace(/\/$/, "")}/_vercel/insights/script.js`;
  try {
    const res = await fetch(scriptUrl, { method: "HEAD", redirect: "manual" });
    const type = res.headers.get("content-type") ?? "";
    if (res.ok && isJsContentType(type)) {
      pass(`Web Analytics script OK (${type})`);
      return;
    }
    const detail = `HTTP ${res.status}, content-type=${type || "n/a"}`;
    const hint =
      "Enable Web Analytics on chisto-mk-landing, then redeploy production.";
    if (strict) {
      fail(`Web Analytics script ${scriptUrl} → ${detail}. ${hint}`);
    } else {
      warn(`Vercel Web Analytics script missing at ${scriptUrl} (${detail}). ${hint}`);
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    if (strict) {
      fail(`Web Analytics probe failed for ${scriptUrl}: ${message}`);
    } else {
      warn(`could not probe Vercel Web Analytics script: ${message}`);
    }
  }
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
  warn("remove stale LAUNCH_HOME_SECTIONS reference from launch.ts");
}
for (const page of ["about: false", "news: false", "press: false"]) {
  if (launchSrc.includes(page)) {
    warn(`LAUNCH_PAGE_VISIBILITY.${page.split(":")[0]} is still false`);
  }
}

const resendKeys = ["RESEND_API_KEY", "RESEND_FROM_EMAIL", "RESEND_NOTIFY_TO"];
const missingResend = resendKeys.filter((k) => !process.env[k]?.trim());
if (missingResend.length > 0) {
  warn(`missing Resend env (forms will fail): ${missingResend.join(", ")}`);
}

const verifyAnalyticsUrl = process.env.VERIFY_ANALYTICS_URL?.trim();
const siteUrl = (process.env.NEXT_PUBLIC_SITE_URL || process.env.LANDING_SITE_URL || "").trim();
if (verifyAnalyticsUrl) {
  // Strict: used for production smoke checks; fails the script on missing JS.
  await probeInsightsScript(verifyAnalyticsUrl, { strict: true });
} else if (siteUrl.startsWith("https://")) {
  // Soft: PR/CI may race a live enable+redeploy — warn only.
  await probeInsightsScript(siteUrl, { strict: false });
} else {
  warn("skip Web Analytics probe (set NEXT_PUBLIC_SITE_URL, LANDING_SITE_URL, or VERIFY_ANALYTICS_URL)");
}

if (failed) {
  process.exit(1);
}
console.log("launch-check: OK");

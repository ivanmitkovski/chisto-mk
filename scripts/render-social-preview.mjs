#!/usr/bin/env node
/**
 * Renders .github/social-preview.svg → .github/social-preview.png (1280×640).
 * Uses the canonical brand mark from apps/landing/public/brand/chisto-mark.svg.
 *
 *   node scripts/render-social-preview.mjs
 */
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const input = path.join(root, ".github/social-preview.svg");
const output = path.join(root, ".github/social-preview.png");
const fontsDir = path.join(root, "apps/mobile/assets/fonts");

execFileSync(
  "npx",
  [
    "--yes",
    "@resvg/resvg-js-cli",
    "--no-system-font",
    "--font-file",
    path.join(fontsDir, "Roboto-Regular.ttf"),
    "--font-file",
    path.join(fontsDir, "Roboto-Medium.ttf"),
    "--font-file",
    path.join(fontsDir, "Roboto-Bold.ttf"),
    "--fit-width",
    "1280",
    input,
    output,
  ],
  { stdio: "inherit", cwd: root },
);

console.log(`Wrote ${output}`);

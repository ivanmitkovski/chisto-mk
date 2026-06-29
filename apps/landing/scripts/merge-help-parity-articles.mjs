#!/usr/bin/env node
/**
 * Merge Help Centre parity articles from content/help/*.json into messages/en|mk|sq.json.
 * Run: node scripts/merge-help-parity-articles.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const contentDir = path.join(root, "content", "help");

const HUB_PATCHES = {
  en: {
    subtitle:
      "Practical guides for Chisto.mk on the web and in the app: pollution sites, reporting, cleanup events, safety, offline use, your account, and troubleshooting.",
    featuredTitle: "Start here",
    featuredIntro: "New to Chisto.mk? Pick a path below or search. Wording matches the app.",
    catalogMetrics: "{count, plural, one {# guide · same terms as in the app} other {# guides · same terms as in the app}}",
    featuredSlugs: ["getting-started", "report-a-site", "join-a-cleanup-event"],
    startHereTitle: "What do you want to do?",
    startHerePaths: [
      {
        id: "report",
        label: "Report pollution",
        description: "Photos, pin placement, and what happens after you submit.",
        href: "/help/report-a-site",
      },
      {
        id: "join",
        label: "Join a cleanup",
        description: "Find events, RSVP, check in, and use event chat.",
        href: "/help/join-a-cleanup-event",
      },
      {
        id: "organize",
        label: "Organize a cleanup",
        description: "Plan, publish, and run an event for volunteers.",
        href: "/help/hosting-a-cleanup-event",
      },
    ],
    searchTips: [
      "Try everyday words: report, draft, QR, heatmap, OTP, points, notification.",
      "If nothing matches, browse the topic cards by category.",
      "Long guides have a table of contents at the top of the article.",
    ],
  },
  mk: {
    subtitle:
      "Практични водичи за Chisto.mk на веб и во апликацијата: загадени места, пријавување, настани за чистење, безбедност, офлајн употреба, сметка и решавање проблеми.",
    featuredTitle: "Започнете тука",
    featuredIntro: "Нови сте на Chisto.mk? Изберете пат подолу или пребарајте. Термините се исти како во апликацијата.",
    catalogMetrics:
      "{count, plural, one {# водич · исти термини како во апликацијата} other {# водичи · исти термини како во апликацијата}}",
    featuredSlugs: ["getting-started", "report-a-site", "join-a-cleanup-event"],
    startHereTitle: "Што сакате да направите?",
    startHerePaths: [
      {
        id: "report",
        label: "Пријавете загадување",
        description: "Фотографии, локација и што следи по поднесувањето.",
        href: "/help/report-a-site",
      },
      {
        id: "join",
        label: "Приклучете се на чистење",
        description: "Најдете настани, RSVP, check-in и chat.",
        href: "/help/join-a-cleanup-event",
      },
      {
        id: "organize",
        label: "Организирајте чистење",
        description: "Планирајте, објавете и водете настан.",
        href: "/help/hosting-a-cleanup-event",
      },
    ],
    searchTips: [
      "Обидете се со секојдневни зборови: report, draft, QR, heatmap, OTP, points, notification.",
      "Ако нема совпаѓање, прегледајте по категорија.",
      "Долгите водичи имаат содржина на страницата на врвот.",
    ],
  },
  sq: {
    subtitle:
      "Udhëzues praktikë për Chisto.mk në web dhe në aplikacion: vende të ndotura, raportim, ngjarje pastrimi, siguri, përdorim offline, llogari dhe zgjidhje problemesh.",
    featuredTitle: "Filloni këtu",
    featuredIntro: "I ri në Chisto.mk? Zgjidhni një rrugë më poshtë ose kërkoni. Termat përputhen me aplikacionin.",
    catalogMetrics:
      "{count, plural, one {# udhëzues · termat e njëjtë si në aplikacion} other {# udhëzues · termat e njëjtë si në aplikacion}}",
    featuredSlugs: ["getting-started", "report-a-site", "join-a-cleanup-event"],
    startHereTitle: "Çfarë doni të bëni?",
    startHerePaths: [
      {
        id: "report",
        label: "Raportoni ndotjen",
        description: "Foto, vendndodhja dhe çfarë ndodh pas dërgimit.",
        href: "/help/report-a-site",
      },
      {
        id: "join",
        label: "Bashkohuni në pastrim",
        description: "Gjeni ngjarje, RSVP, check-in dhe chat.",
        href: "/help/join-a-cleanup-event",
      },
      {
        id: "organize",
        label: "Organizoni pastrim",
        description: "Planifikoni, publikoni dhe udhëheqni një ngjarje.",
        href: "/help/hosting-a-cleanup-event",
      },
    ],
    searchTips: [
      "Provoni fjalë të zakonshme: report, draft, QR, heatmap, OTP, points, notification.",
      "Nëse nuk ka përputhje, shfletoni sipas kategorisë.",
      "Udhëzuesit e gjatë kanë tabelë përmbajtjeje në krye.",
    ],
  },
};

const CATEGORY_PATCHES = {
  en: {
    basics: { label: "Getting started" },
    map: { label: "Map and sites" },
    reporting: { label: "Reporting" },
    events: { label: "Cleanups" },
    profile: { label: "Your account" },
  },
  mk: {
    basics: { label: "Започнување" },
    map: { label: "Мапа и места" },
    reporting: { label: "Пријавување" },
    events: { label: "Чистења" },
    profile: { label: "Вашата сметка" },
  },
  sq: {
    basics: { label: "Fillimi" },
    map: { label: "Harta dhe vendet" },
    reporting: { label: "Raportimi" },
    events: { label: "Pastrimet" },
    profile: { label: "Llogaria juaj" },
  },
};

for (const locale of ["en", "mk", "sq"]) {
  const messagesPath = path.join(root, "messages", `${locale}.json`);
  const articlesPath = path.join(contentDir, `articles.${locale}.json`);
  const messages = JSON.parse(fs.readFileSync(messagesPath, "utf8"));
  const articles = JSON.parse(fs.readFileSync(articlesPath, "utf8"));

  messages.helpCentre.hub = {
    ...messages.helpCentre.hub,
    ...HUB_PATCHES[locale],
  };
  messages.helpCentre.categories = CATEGORY_PATCHES[locale];
  messages.helpCentre.articles = articles;

  fs.writeFileSync(messagesPath, `${JSON.stringify(messages, null, 2)}\n`, "utf8");
  console.log(`merged help articles → messages/${locale}.json (${Object.keys(articles).length} articles)`);
}

console.log("merge-help-parity-articles: OK");

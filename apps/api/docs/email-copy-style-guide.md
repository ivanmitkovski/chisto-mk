# Email copy style guide (Chisto.mk)

Central source: `apps/api/src/email/util/email-copy.ts` (body, subject, CTA) and `email-labels.ts` (enum labels in admin moderation emails). Shell/footer: `getEmailShellCopy()` in the same module. Layout: `templates/base.hbs`.

## Supported locales

| Channel | Locales | Fallback |
|---------|---------|----------|
| Transactional email | `mk`, `en` | `mk` when locale is unknown (`resolveLocale`) |
| Mobile app / push | `mk`, `en`, `sq` | User locale → device → `mk` |

Albanian (`sq`) is **not** yet wired for email. Adding a locale requires extending `EmailLocale`, `CTA_LABELS`, every `getCopy` branch, `email-labels` maps, shell copy, and `formatDateTime` locale tags.

## Tone

- **Transactional, civic, professional** — short sentences, active voice, no marketing fluff.
- **MK default** — standard literary Macedonian; avoid regionalisms (see `apps/mobile/packages/chisto_localization/docs/mk-environmental-terminology.md`).
- **EN** — plain international English; same information density as MK.

## Terminology (MK)

| Concept | Preferred MK | Avoid |
|---------|--------------|-------|
| Pollution report | пријава | signal, ticket |
| Site / location | локалитет | место (when meaning map site) |
| Cleanup event | настан за чистење / акција за чистење | акција alone (ambiguous) |
| Volunteer | доброволец | волонтер (acceptable in some legacy strings; prefer доброволец in new copy) |
| Harassment (UGC) | **Вознемирување** | Вреќање (homophone confusion with “bag”) |
| Waste (gear) | вреќи за отпад | џувалја |
| Collected bags (count) | ќеси | торби |

Align UGC reason labels with mobile: `safetyReportReasonHarassment` → **Вознемирување**.

## Punctuation & lists

- Use **commas** between parallel verbs in one sentence:  
  `Пријавувајте загадувања, следете ги локалитетите и учествувајте…`  
  Not: `…загадувања и следете… и учествувајте…` (double *и*).
- Use Macedonian quotation marks `„…“` for titles and previews in MK.
- Include definite articles where natural: `контактирајте ја поддршката` (not `контактирајте поддршка`).

## Template inventory (2026-06-09 audit)

### Auth / account (email)

| Template ID | Trigger | MK subject (summary) |
|-------------|---------|----------------------|
| `welcome` | Account created | Добредојдовте на Chisto.mk |
| `password_reset` | Reset OTP | Ресетирајте ја лозинката… |
| `password_changed` | Password updated | Лозинката… е променена |
| `admin_invite` | Admin onboarding | Покана за Chisto.mk Admin |

**Not email today:** phone/email OTP verification (SMS/app), login MFA, account recovery beyond password reset.

### Platform / notifications (email via `email-event-mapper`)

| Template ID | Notification |
|-------------|--------------|
| `report_received` | Report submitted |
| `report_approved` / `report_declined` | Moderation outcome |
| `report_merged` | Duplicate merge roles |
| `event_approved` / `event_declined` | Event moderation |
| `event_published` | New event at followed site |
| `event_completed_award` / `event_completed_no_show` | Points after event |
| `site_upvote` / `site_comment` | Site activity |

**Push/in-app only (no email template):** achievements, nearby reports, event chat, generic system alerts, event reminders/cancellations (unless added later).

### Admin moderation (email)

| Template ID | Purpose |
|-------------|---------|
| `admin_moderation_new_report` | Queue: new report |
| `admin_moderation_event_pending` | Queue: event approval |
| `admin_moderation_ugc_report` | UGC flag |
| `admin_moderation_checkin_risk` | Suspicious check-in |

## Dynamic content

- Interpolation: `firstName`, `reportNumber`, `eventTitle`, `points`, `code`, etc. in `getCopy` context.
- Dates: `formatDateTime` / `formatDateRange` with `mk-MK` or `en-GB`.
- No plural rules in email copy yet; bag/point counts use numeric + fixed noun (ќеси, поени).
- HTML escaping in `buildBodyHtml`; hyphen collapse in plain text before escape.

## QA checklist (per template / locale)

- [ ] Subject non-empty, ≤ ~70 chars where possible
- [ ] Headline matches intent
- [ ] Lead readable on mobile (one–two sentences)
- [ ] CTA label + URL present (except admin invite uses invite URL)
- [ ] Footer disclaimer + prefs/unsubscribe links (transactional shell)
- [ ] Test with long `eventTitle` / `firstName` / preview text
- [ ] MK + EN parity (same facts, not word-for-word calque)

Preview locally: `npm run email:preview` (see `apps/api/scripts/render-email-preview.ts`).

## Audit log (2026-06-09)

| Issue | Fix |
|-------|-----|
| Welcome MK: awkward double *и* | Comma list: `загадувања, следете… и учествувајте…` |
| UGC `harassment` label `Вреќање` | **Вознемирување** (matches app) |
| Password changed MK missing article | `контактирајте ја поддршката` |
| Report declined MK footer | `Забелешка од модератор:` |

No EN grammar defects found in static copy. Cross-locale parity verified for all 19 template IDs in `email-copy.spec.ts`.

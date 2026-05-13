# Reports wizard — accessibility sign-off

This document records execution of the checklist in `docs/reports-outbox-runbook.md` (section **UX / accessibility sign-off (wizard)**).

| Field | Value |
|-------|--------|
| **Date** | 2026-05-13 |
| **Tester / role** | Engineering (automated checklist + code review of semantics) |
| **Build / branch** | `main` (post reporting-flow hardening) |

## Devices

| Platform | OS version | Notes |
|----------|------------|--------|
| iOS | 18.x (template) | VoiceOver: evidence grid, category sheet, location confirm, review — verify `LocationPickerView` live region updates |
| Android | 15 (template) | TalkBack: focus order on wizard stages and bottom bar |

Replace template rows with physical device versions used in your release QA.

## Results

| Check | Pass | Notes / issue link |
|-------|------|---------------------|
| VoiceOver — evidence grid labels | ☐ | |
| VoiceOver — category sheet | ☐ | |
| VoiceOver — location confirm + live region | ☐ | |
| VoiceOver — review / submit | ☐ | |
| TalkBack — same surfaces | ☐ | |
| Map — non-color error / state cues | ☐ | |
| MK / SQ pseudo-locale — long strings within `ReportFieldLimits` | ☐ | |

**P1 blockers**: none recorded for this sign-off template (fill if any).

When releasing to production, complete the table with **Pass** ticks on real devices and attach links to any tracked defects.

# Deep link inventory

## Universal / app links

| Pattern | Parser | Destination | ID format | Status |
|---------|--------|-------------|-----------|--------|
| `https://chisto.mk/sites/:id` | `DeepLinkRouter` | `/sites/detail/:id` | cuid | Supported |
| `https://chisto.mk/events/:id` | `DeepLinkRouter` | Event detail | cuid or UUID | Supported |
| `chisto://app/events/detail?eventId=` | `DeepLinkRouter` | Event detail | cuid or UUID | Supported |
| `.../app/reports/new` | `DeepLinkRouter` | New report wizard | — | Supported (location gate) |
| `.../app/home/map-focus?siteId=` | `DeepLinkRouter` | `/map` focus | cuid | Supported |
| `.../app/home?tab=events` | `DeepLinkRouter` | `/events` | — | Supported |

## Notification taps

| Entry | Resolver | Destination | Back stack |
|-------|----------|-------------|------------|
| In-app inbox | `NotificationInboxRouter` | Root push | Entity → **Notifications** → Shell |
| Push / local | `NotificationOpenRouter` | Root push | Entity → **Shell** |
| Cold-start push | `ColdStartCoordinator` | Root push | Entity → **`/feed`** |
| Resume drain | `drainAndApplyPendingPushState` | **None** (bell/inbox only) | — |

## Root overlay routes (notification + deep link)

| Route | Screen |
|-------|--------|
| `/notifications` | `NotificationsScreen` |
| `/reports/detail/:reportId` | `ReportDetailRouteScreen` |
| `/profile/points-history` | `ProfilePointsHistoryRouteScreen` |
| `/events/detail/:eventId` | `EventDetailScreen` |
| `/feed/:siteId` | Site detail (shell child on root stack) |

## Internal navigation

| Entity | Route / mechanism | Wired from notifications |
|--------|-------------------|---------------------------|
| Notifications inbox | `/notifications` (root push) | Feed bell |
| Report detail | `/reports/detail/:reportId` | Yes |
| Pollution site | `/feed/:siteId` | Yes |
| Event detail | `/events/detail/:eventId` | Yes |
| Event chat | `/events/chat` | Yes |
| Profile points | `/profile/points-history` | ACHIEVEMENT |
| Feature guide | `/feature-guide` redirect (external only) | WELCOME |
| QR check-in | Event check-in routes | Not via notification |

## Backend notification types (mobile-routed, API-emitted)

| Type | Payload highlights | Mobile destination |
|------|-------------------|-------------------|
| `WELCOME` | `kind: welcome` | Feature guide (external) / coach flag (inbox) |
| `SITE_UPDATE` | `siteId`, `status`, `targetTab` | Feed site detail |
| `ACHIEVEMENT` | `kind: level_up`, `level` | Profile points history |
| `NEARBY_REPORT` | `siteId`, `targetTab: 0` | Map / feed site detail |

## Known gaps (intentional)

- **Public user profile deep links** — not supported; no public profile screen exists.
- Direct comment-thread URL — use site detail + `initialAction`.
- Admin web — separate app.
- QR check-in via notification — not wired.

## Invalid / edge cases

| Case | Expected UX |
|------|----------------|
| Deleted report/site/event | Localized snack; no crash |
| Missing IDs | No navigation; diagnostic logged |
| Unauthorized | Deep link queued until sign-in |
| Offline | Report detail uses session cache + stale banner |
| Push open before navigator ready | Bounded cold-start retry, then snack on failure |
| Inbox → entity → Back | Returns to Notifications (not Home) |

## Entry point audit (2026-06 stack fix)

| Entry | Mechanism | Compliant |
|-------|-----------|-----------|
| `DeepLinkRouter` entity routes | `AppNavigation.pushEventDetail` / `pushSiteDetail` / `pushNewReport` | Yes |
| `DeepLinkRouter` tab/map routes | `navigateToHomeMapFocus` / `navigateToHomeEvents` (`go`) | Yes (no inbox) |
| `ColdStartCoordinator` | `NotificationOpenRouter` → `origin: external` | Yes |
| `NotificationInboxRouter` | `origin: inbox`; root `push` only | Yes |
| `NotificationOpenRouter` | `origin: external` | Yes |
| Feed bell | `AppNavigation.pushNotifications()` | Yes |
| Report notifications | `AppNavigation.pushReportDetail()` (not `go('/reports')`) | Yes |

## Test coverage

Automated tests live under:

- Mobile: `apps/mobile/test/features/notifications/` (resolver, drain, routing parity, stack policy)
- API: notification emitter tests under `apps/api/test/`

Manual QA matrix: [`notification-routing-architecture.md`](notification-routing-architecture.md).

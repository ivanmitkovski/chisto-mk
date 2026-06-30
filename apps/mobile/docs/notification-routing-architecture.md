# Notification routing architecture

## Ingress

| Source | Handler | Tap delivery |
|--------|---------|--------------|
| FCM foreground | `PushNotificationLocal` → local banner | `localNotificationTaps` |
| FCM background (warm) | `FirebaseMessaging.onMessageOpenedApp` | `notificationTaps` |
| FCM terminated | `consumePendingLaunchNotification` → `ColdStartCoordinator` | After session ready |
| Android background data-only | Background isolate → local banner | Stashed tap → genuine tap handlers only |
| In-app inbox | `NotificationsScreen._openNotification` | `NotificationInboxRouter` |
| Scheduled local reminders | `flutter_local_notifications` tap | JSON payload → `NotificationOpenRouter` |

## Navigation stack policy

Notification destinations open on the **root GoRouter stack** (`appRootNavigatorKey`). The inbox is a root route at `/notifications` (not a nested branch navigator push).

| Entry source | Stack after open | Back from entity |
|--------------|------------------|------------------|
| **Inbox** | `Shell → Notifications → Entity` | Entity → **Notifications** → Shell |
| **Push** (warm/foreground) | `Shell → Entity` | Entity → **Shell** (current tab) |
| **Push cold-start** | `Shell → Entity` | Entity → **Shell `/feed`** |
| **Deep link** | `Shell → Entity` (`push`) | Entity → Shell |

Rules:

- Never `Navigator.pop()` the inbox before opening a destination.
- Never `go()` when preserving an inbox back stack; use `router.push` on the root navigator.
- `go()` / `goBranch()` remain valid for tab switches, auth redirects, and **external** notification targets that intentionally reset location (e.g. WELCOME → feature guide).

`NotificationNavigationOrigin` (`inbox` vs `external`) is threaded from `NotificationInboxRouter` and `NotificationOpenRouter` into `NotificationNavigationExecutor`.

## Payload contract

Server builds FCM data via [`notification-push-data.ts`](../../api/src/notifications/util/notification-push-data.ts). All values are strings.

Common keys: `notificationId`, `type`, `notificationType`, `title`, `body`, `unreadCount`.

Entity keys (when applicable): `reportId`, `siteId`, `eventId`, `commentId`, `actorUserId`, `targetAction`, `targetTab`, `kind`, `threadTitle`, `messageId`.

## Routers

- **`resolveNotificationNavigationTarget`** — pure `(type, data)` → target (single source of truth).
- **`NotificationNavigationExecutor`** — performs root-stack navigation for inbox and push; uses fallback context for failure snacks.
- **`NotificationInboxRouter`** — inbox adapter (`origin: inbox`; mark read handled by screen).
- **`NotificationOpenRouter`** — push/local adapter (`origin: external`).
- **`ColdStartCoordinator`** — one launch intent after bootstrap + session ready.

## Target resolution (type + data)

| Type | `data.kind` | Required IDs | Destination |
|------|-------------|--------------|-------------|
| `SYSTEM` | any (incl. `digest_deferred`) | `reportId` | Root `/reports/detail/:id` |
| `SYSTEM` | `report_received` | `siteId` (no `reportId`) | Feed site detail |
| `REPORT_STATUS` | — | `reportId` | Root `/reports/detail/:id` |
| `CLEANUP_EVENT` | * | `eventId` | Event detail |
| `EVENT_CHAT` | — | `eventId` | Event chat |
| `UPVOTE`, `COMMENT`, `SITE_UPDATE`, `REPORT_STATUS` (no reportId), `NEARBY_REPORT` | — | `siteId` | Feed site detail (+ action/highlight) |
| `ACHIEVEMENT` | `level_up` (optional) | — | Root `/profile/points-history` |
| `WELCOME` | `welcome` | — | Feature guide (external) or coach-tour flag (inbox) |
| Missing entity | — | — | Localized failure snack |

Report notifications prefer **`reportId`** over **`siteId`** so two reports on the same site open distinct report details.

## Backend emitters (2026-06 release)

| Type | Trigger | Key payload |
|------|---------|-------------|
| `WELCOME` | First phone verification (`auth-otp.service`) | `{ kind: 'welcome' }` |
| `SITE_UPDATE` | Admin / automated site status → VERIFIED, CLEANUP_SCHEDULED, IN_PROGRESS, CLEANED | `{ siteId, status, targetTab: '0' }` |
| `ACHIEVEMENT` | Level-up after points credit | `{ kind: 'level_up', level, levelTierKey }` |
| `NEARBY_REPORT` | Report approved (public site) | `{ siteId, targetTab: '0' }` |

## Cold start

1. `markBootstrapReady()` — app bootstrap complete.
2. `markSessionReady()` — initial route resolution complete (`InitialRouteScreen`).
3. `consumePendingLaunchNotification()` — queue FCM terminated tap (`PushSetupCoordinator.bootstrap`).
4. `ColdStartCoordinator.tryApply()` — push beats deep link once per launch (bounded post-frame retry if navigator context is null).
5. `drainAndApplyPendingPushState()` — on resume, **inbox/unread bump only** (no auto-navigation from stashed delivery payloads).

## Reliability hardening (2026-06)

- Unified resolver + executor for push and inbox.
- `SYSTEM` + `reportId` routes to report detail even when `kind` was overwritten (e.g. `digest_deferred`).
- Push/cold-start failures show localized snacks via root navigator fallback context.
- Profile achievements / level-up → root points history route.
- Drain on resume does **not** navigate; genuine taps use `onMessageOpenedApp`, `getInitialMessage`, or local notification tap.

## Manual QA checklist

See [`deep-link-inventory.md`](deep-link-inventory.md).

| Scenario | Foreground | Background | Terminated |
|----------|------------|------------|------------|
| Inbox → event → Back | Notifications | Same | N/A |
| Push → event → Back | Shell tab | Same | `/feed` |
| `report_received` tap | Report detail | Report detail | Report detail |
| `REPORT_STATUS` | Report detail | Report detail | Report detail |
| `CLEANUP_EVENT` | Event detail | Event detail | Event detail |
| `EVENT_CHAT` | Chat | Chat | Chat |
| `COMMENT` | Site + comments | Same | Same |
| `WELCOME` | Feature guide | Same | Same |
| `ACHIEVEMENT` | Profile points | Same | Same |
| `NEARBY_REPORT` | Map site | Same | Same |
| Deleted entity | Friendly error | Same | Same |
| Offline report open | Cached detail + stale banner | Same | Same |

## Known limitation

Public user profile deep links are intentionally unsupported (no public profile screen).

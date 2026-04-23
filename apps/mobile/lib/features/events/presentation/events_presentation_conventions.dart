// Events presentation conventions and implementation inventory.
//
// -----------------------------------------------------------------------------
// 1) Primary user journeys
// -----------------------------------------------------------------------------
// - Discovery journey:
//   EventsFeedScreen -> EventDetailScreen -> join/leave -> reminder.
// - Organizer journey:
//   EventDetailScreen -> OrganizerCheckInScreen -> open/pause/resume check-in ->
//   attendee list updates -> end event -> OrganizerEventCompletionSheet (next steps +
//   optional "Add cleanup photos now" opens EventCleanupEvidenceScreen) -> detail ->
//   EventCleanupEvidenceScreen / impact feedback.
// - Attendee journey:
//   EventDetailScreen -> attendee scanner route -> redeem QR -> back to detail with
//   checked-in banner state.
//
// Route entry points:
// - EventsNavigation (feature navigation helpers)
// - AppRoutes.events* (named routes + Cupertino transitions for check-in)
// - Create entry: [EventsNavigation.openCreate] and [CreateEventSheet] both gate organizer
//   certification; [ApiAuthRepository.restoreSession] hydrates `organizerCertifiedAt` from
//   secure storage before `/auth/me` when the network is temporarily unavailable.
// - Field mode + offline hub: OrganizerDashboardScreen pushes FieldModeScreen (MaterialPageRoute) for offline
//   queue review/sync and opens OfflineWorkHubSheet for cross-lane pending work — not registered on AppRoutes;
//   document in release checklist (docs/events-release-checklist.md).
//
// -----------------------------------------------------------------------------
// 1b) Typography — AppTypography.events* role map
// -----------------------------------------------------------------------------
// Prefer `Theme.of(context).textTheme` only inside `AppTypography` helpers so text scales.
// Barrel import: `events_typography.dart` re-exports `app_typography.dart`.
//
// Discovery & cards: eventsListCardTitle, eventsListCardMeta, eventsHeroCardTitle,
//   eventsHeroCardMeta, eventsCardBadgeAccent, eventsCardBadgeMuted.
// Detail chrome: eventsDetailHeadline, eventsSectionTitle,
//   eventsBodyProse, eventsBodyMuted, eventsInlineLabel, eventsGridPropertyValue,
//   eventsCaptionStrong, eventsMetricValue, eventsDisplayStat.
// Sheets & filters: eventsSheetTitle, eventsSheetTextLink, eventsSheetSectionLabel,
//   eventsSheetChipLabel, eventsSheetDateTileLabel, eventsSheetDateTileValue,
//   eventsPrimaryButtonLabel.
// Forms: eventsFormFieldValue, eventsFormSectionLabel, eventsFormFieldLabel, eventsFormError.
// Chat: eventsChatMessageBody, eventsChatAuthorName, eventsChatTimestamp, eventsChatSystemLine
//   (bubble colors: `.copyWith(color: …)` on top of these bases).
// Check-in / QR: eventsQrCaption. Semantics: eventsDestructiveCaption, eventsWarningCaption.
// Dense titles: eventsScreenTitle.
// Feed & calendar: eventsFeedScreenTitle, eventsSearchFieldText, eventsSearchFieldPlaceholder,
//   eventsInlineInfoBanner, eventsFeedSectionTitle, eventsMicroSectionHeading,
//   eventsCalendarMonthTitle, eventsCalendarEmbeddedMonthTitle, eventsCalendarWeekdayLabel,
//   eventsCalendarDayNumber, eventsCalendarSectionHeader, eventsCalendarAgendaTitle,
//   eventsSupportingCaption, eventsEmptyStateTitle, eventsEmptyStateSubtitle.
//
// -----------------------------------------------------------------------------
// 2) Mobile -> API surface matrix (current contracts)
// -----------------------------------------------------------------------------
// Events list/detail/lifecycle:
// - GET    /events?status=...&category=...&limit=...&cursor=...
//   (category: comma-separated mobile keys; status: comma-separated lifecycle keys)
// - GET    /events/:id
// - GET    /events/:id/participants?limit=...&cursor=...  (joiners only; organizer from detail)
// - POST   /events (same calendar day start/end in Europe/Skopje; end by 23:59 local)
// - PATCH  /events/:id
// - PATCH  /events/:id/status
// - PATCH  /events/:id/reminder
// - POST   /events/:id/join
// - DELETE /events/:id/join
// - POST   /events/:id/after-images
// - GET    /events/:id/impact-receipt
//   (aggregate impact read model: counts + signed evidence/after URLs; no roster.
//   400 EVENTS_IMPACT_RECEIPT_NOT_AVAILABLE for upcoming or cancelled.)
//
// -----------------------------------------------------------------------------
// 2d) Push notification `data` keys (FCM — contract for mobile routing)
// -----------------------------------------------------------------------------
// Handled by [NotificationOpenRouter] / [PushNotificationService]. Unknown types
// should degrade to the events tab; payloads must never crash cold start.
//
// - `CLEANUP_EVENT`: required `eventId` (UUID string). Optional `kind` (e.g. `published`)
//   may bump [eventsFeedRemoteRefreshTick] before navigation (see main.dart).
// - `EVENT_CHAT`: required `eventId` (UUID string). Optional `threadTitle` (non-PII event
//   title for app bar); when absent the client hydrates from cache/prefetch where possible.
//
// -----------------------------------------------------------------------------
// 2b) Impact receipt (upgrade #1) — product rules (server is source of truth)
// -----------------------------------------------------------------------------
// - Eligibility: same visibility as GET /events/:id (`visibilityWhere`). Receipt
//   is returned only for lifecycle IN_PROGRESS or COMPLETED. UPCOMING and CANCELLED
//   return 400 EVENTS_IMPACT_RECEIPT_NOT_AVAILABLE (mobile maps via ARB).
// - Privacy: counts only (participantCount, checkedInCount, reportedBagsCollected);
//   no attendee identities. Organizer display name matches event detail exposure.
// - Bags on the receipt: `liveMetric.reportedBagsCollected` only — not device-local
//   impact feedback (`EventFeedbackLocalCache`) until that data is persisted on API.
// - Completeness (completed): `full` when after photos and structured evidence both
//   exist; partial enums when one or both are missing; `in_progress` while the event
//   is live.
// - Share URL: `event_share_payload.dart` (`/events/:id` on share base). Rich link
//   preview / universal landing page is deferred (see docs/events-release-checklist.md).
//
// -----------------------------------------------------------------------------
// 2c) Offline work coordinator (upgrade #2 — foreground reliability)
// -----------------------------------------------------------------------------
// - [EventOfflineWorkCoordinator] is a singleton started from ServiceLocator.initialize and
//   disposed on ServiceLocator.reset. It owns a debounced (~550ms), serialized drain after
//   [ConnectivityGate.watch] reports online and on app resume ([WidgetsBindingObserver] bridge).
// - Drain order (deterministic, single flight): check-in redeem queue → field batch
//   ([FieldModeSyncService] / POST /events/field-batch) → chat text outbox ([ChatOutboxSync],
//   bounded 50 sends per drain, exponential backoff on retryable failures).
// - Gating: drains no-op when [AuthState.isAuthenticated] is false or [ConnectivityGate.isOnline]
//   is false (empty connectivity list counts as online — same contract as [ConnectivityGate] docs).
// - Privacy: hub UI shows counts only; [logEventsDiagnostic] emits stable codes only (no bodies,
//   titles, ids, or queries). Chat outbox still stores message bodies in SQLite — cleared on
//   logout via [ChatOutboxStore.clearAll] (see auth repository).
// - OS background workers (WorkManager / BGTaskScheduler) are explicitly out of scope for v1;
//   see docs/events-release-checklist.md § “Phase 2 — OS background”.
//
// Check-in:
// - PATCH  /events/:id/check-in
// - POST   /events/:id/check-in/session/rotate
// - GET    /events/:id/check-in/qr
// - GET    /events/:id/check-in/attendees
// - POST   /events/:id/check-in/manual
// - DELETE /events/:id/check-in/attendees/:checkInId
// - POST   /events/:id/check-in/redeem
//
// Event detail fields required by UI and expected from GET /events/:id:
// - identity + copy: id/title/description/category
// - schedule: scheduledAt/endAt/status
// - organizer/site: organizerId/organizerName/siteId/siteName/siteImageUrl
// - participation: participantCount/maxParticipants/isJoined
// - reminders: reminderEnabled/reminderAt
// - check-in: isCheckInOpen/activeCheckInSessionId/checkedInCount/attendeeCheckInStatus
// - media + moderation: afterImagePaths/moderationApproved
//
// -----------------------------------------------------------------------------
// 3) Presentation/l10n gaps that must stay tracked
// -----------------------------------------------------------------------------
// Converted in this pass (no hardcoded copy should regress):
// - reminder_section.dart
// - participants_section.dart
// - date_time_section.dart
// - description_section.dart
// - after_photos_gallery.dart
// - category_section.dart
// - organizer_section.dart
// - event_details_grid.dart
// - events_filter_chips.dart
// - events_feed_screen.dart
// - events_calendar_view.dart
// - event_calendar.dart
// - gear_section.dart, impact_summary_section.dart, location_chip.dart
// - events_empty_states.dart (feed + search empty)
// - site_picker_sheet.dart, event_success_dialog.dart, time_range_picker.dart
// - recent_searches_shelf.dart, after_tab.dart (+ AddPhotosEmptyState strings)
// - cleanup_fullscreen_gallery_page.dart (semantics)
//
// Participant roster: ParticipantsSection peeks the first page of joiners via
// EventsRepository.fetchParticipants (GET /events/:id/participants) for the avatar stack, and
// the full sheet paginates the same endpoint; checked-in badges on the sheet apply only to
// the current user (no inferred check-in state for other rows).
//
// Keep auditing for:
// - newly introduced tooltip/title/snackbar strings in events/presentation
// - semantics labels in modal sheets and destructive actions
// - organizer_event_summary_card.dart: quick-action labels and participant counts must use ARB
//   (eventsCheckInTitle, eventsOrganizerDashboardEvidenceAction, eventsOrganizerDashboardParticipants*)
// - chat_location_picker_sheet.dart: primary CTA via eventChatSendLocation
// - Calendar day strings: use formatEventCalendarDate(context, event.date); do not reintroduce
//   English-only month lists on EcoEvent
//
// -----------------------------------------------------------------------------
// 3b) Events feed: server vs client filtering (single refresh path)
// -----------------------------------------------------------------------------
// - Advanced filters (sheet) are stored in EcoEventSearchParams (categories,
//   optional lifecycle multi-select, date range). The search field sets `q` on
//   the same object via refreshEvents.
// - Top pills (EcoEventFilter) are merged by EventsFeedSearchMerge.mergedForChip
//   before every GET /events (pull-to-refresh, chip change, sheet apply):
//   * Upcoming / Past → override lifecycle for the request (chip wins over sheet
//     status toggles).
//   * Nearby / My events → same query as All + sheet; Nearby sorts by distance,
//     My events filters client-side to organizer or joined rows.
// - Cursor pagination (loadMore) follows the repository's active merged params.
//
// -----------------------------------------------------------------------------
// 3d) Discovery shelf — "this week" (upgrade #3)
// -----------------------------------------------------------------------------
// **Week definition (product)**: the ISO calendar week (Monday–Sunday) in
// **Europe/Skopje** that contains the reference instant, inclusive of both endpoints as
// calendar **dates** (`dateFrom` / `dateTo` on GET /events). Implemented by
// `skopjeCalendarWeekBoundsInclusive` + `EcoEventSearchParams.discoveryThisSkopjeCalendarWeek`.
// This is a **Skopje wall-calendar** window, not a rolling 7-day interval from "now".
//
// **UI**: [EventsThisWeekShelf] on [EventsFeedScreen] (list mode, non-calendar, empty search):
// horizontal tiles only; collapses to [SizedBox.shrink] while empty or still loading (no second
// spinner — pull-to-refresh uses [CupertinoSliverRefreshControl] only).
// Strip loads via [EventsRepository.fetchEventsSnapshot] so the main feed query is unchanged.
// Client sorts snapshot rows by `siteDistanceKm` then lifecycle rank (see feed controller).
//
// -----------------------------------------------------------------------------
// 3c) Event detail section order (see DetailContent doc comment)
// -----------------------------------------------------------------------------
// Title → banners → EventDetailGroupedPanel (facts) → weather (if coords) → gear →
// description → participation → participants → organizer → analytics → after
// photos → impact receipt link (in progress / completed) → impact. Stagger delays:
// event_detail_stagger.dart.
//
// -----------------------------------------------------------------------------
// 4) Data freshness and cache rules (mobile)
// -----------------------------------------------------------------------------
// - Detail open path should force refresh /events/:id to avoid stale check-in
//   fields when coming from cached feed rows.
// - After server-side check-in mutations, keep optimistic local updates for
//   isCheckInOpen and then schedule non-blocking detail refresh.
// - API-backed repositories are source-of-truth; in-memory repositories emulate
//   behavior but never skip listener notifications on state-changing flows.
//
// -----------------------------------------------------------------------------
// 5) Image pipeline notes
// -----------------------------------------------------------------------------
// EcoEventCoverImage states:
// - empty source -> neutral placeholder
// - loading -> skeleton shimmer-like placeholder (not identical to error)
// - error -> explicit failure icon/surface
// - network/asset -> rendered image with the same clipping contract
//
// Detail/feed/hero usage should preserve perceived layout stability while image
// loads to avoid content jumps.
//
// -----------------------------------------------------------------------------
// 5b) UX system (typography, touch targets, haptics, loading)
// -----------------------------------------------------------------------------
// Typography ladder — use [Theme.of] scaling via [AppTypography] helpers:
// - eventsDetailHeadline: [TitleSection] (schedule line removed — see [DateTimeSection])
// - eventsSectionTitle: [DetailSectionHeader]
// - eventsListCardTitle / eventsListCardMeta: [EcoEventCard] rows
// - eventsHeroCardTitle / eventsHeroCardMeta: [HeroEventCard] on imagery
// - eventsFormFieldValue: create/edit picker value rows
// - emptyStateTitle / emptyStateSubtitle: feed empty + search empty states
//
// Touch targets: prefer at least 44×44 logical px for icon buttons, filter sheet
// chips/tiles, and pill filters; [PrimaryButton] / detail sticky CTA use 56 / 54.
//
// Haptics ([AppHaptics], skips when reduce motion disables animations):
// - tap: filter toggles, sheet rows, secondary navigation
// - light: low-emphasis confirmations (some calendars, participant copy)
// - medium: stronger list refresh / dashboard beats
// - softTransition: card→detail, maps, location surfaces
// - success / warning: mutations, validation, check-in outcomes
//
// Async panels: skeleton → content → retry (e.g. organizer analytics, weather);
// participant roster sheet shows loading then list or coded error + retry.
//
// -----------------------------------------------------------------------------
// 6) Product-optionals (gated, currently deferred unless explicitly approved)
// -----------------------------------------------------------------------------
// - OS-level reminder scheduling/push notifications (FCM `CLEANUP_EVENT` with
//   optional `eventId` opens EventDetailScreen; without `eventId` opens events tab)
// - Universal links / cold-start deep links (add `app_links` + iOS/Android config;
//   share URL handling for event detail)
// - manual organizer check-in: POST body `userId` (must be EventParticipant)
// - moderation-specific UX flows beyond basic approved/pending states
// - analytics instrumentation for event funnel and check-in outcomes
// - per-user privacy controls for roster visibility (if product requires)
//
// See docs/events-deferred-epics.md for epic-level notes and sign-off expectations.
//
// -----------------------------------------------------------------------------
// 7) Create event screen (navigation + first paint)
// -----------------------------------------------------------------------------
// - Route: AppRoutes.eventsCreate uses CupertinoPageRoute (iOS edge swipe-back);
//   PopScope(canPop: !_isDirty) + onPopInvokedWithResult shows discard when needed.
// - First paint: short bootstrap skeleton (CreateEventScreenSkeleton) then
//   AnimatedSwitcher to form; section FadeTransitions respect reduce motion.
// - Schedule: one calendar day plus start/end times; product rule is same local day,
//   end strictly after start, end by 23:59 (see [event_schedule_constraints.dart];
//   API `EVENTS_END_DIFFERENT_SKOPJE_CALENDAR_DAY` / `EVENTS_END_AFTER_SKOPJE_LOCAL_DAY`).
//
// -----------------------------------------------------------------------------
// 8) Event detail screen — layout and typography
// -----------------------------------------------------------------------------
// - Hero expanded height: [kEventDetailHeroExpandedHeight] in event_detail_layout.dart
//   (keep [HeroImageBar] and [EventDetailSkeleton] in sync).
// - Major blocks below the hero: [AppSpacing.lg] between title, completed callouts,
//   grouped metadata panel, gear, description, participants, organizer, galleries,
//   impact, reminder, and check-in banner.
// - Grouped metadata: [EventDetailGroupedPanel] wraps location, date/time, category,
//   optional scale/difficulty, recurrence; rows use embedded* flags. Event chat opens
//   from [HeroImageBar] when the user may access it (not inside the grouped panel).
// - Title: status capsule uses [AppSpacing.radiusPill] + [AppTypography.pillLabel]-derived
//   styling; event name uses [AppTypography.eventsDetailHeadline] (theme headlineMedium).
//
// -----------------------------------------------------------------------------
// 9) Manual QA matrix (living checklist)
// -----------------------------------------------------------------------------
// - Reduced motion ON: staggered sections / pulse visuals
// - Large text + narrow width: event detail and organizer check-in overflow checks
// - Dynamic Type (largest) + narrow device: sticky CTA, chat composer, field mode list,
//   quiz option rows — no clipping; verify docs/events-release-checklist.md release row.
// - Airplane mode: feed refresh, detail open, join/reminder/check-in feedback
// - Offline work hub: organizer dashboard badge when pending work exists; sheet counts for
//   check-in / field / chat; Sync now completes without PII in diagnostics; terminal chat rows
//   surface as “needs attention” and open-chat deep link + snack (ARB `eventsOfflineWorkResolveInChat`)
// - Organizer pause/resume while screen is open: QR availability and banners
// - Attendee scanner: invalid/expired/wrong-event/rate-limit feedback paths
// - Impact receipt: entry from completed/in-progress detail + organizer completion sheet;
//   load OK (full + partial completeness), 400 not-available (upcoming/cancelled deep link),
//   offline/error retry; share + copy link (iOS popover origin); large text + reduce motion
// - Participants sheet: loading, error+retry, organizer-only (count 0), multi-page fetch
// - Slow network: empty states, site picker, participant roster open from detail
// - Create event: Cupertino swipe-back vs dirty discard dialog; bootstrap skeleton timing
// - Optional API smoke: integration_test/events_journey_smoke_test.dart and
//   integration_test/event_chat_smoke_test.dart with --dart-define=API_URL and
//   INTEGRATION_TEST_ACCESS_TOKEN (see docs/events-release-hardening.md). Optional
//   curl preflight: scripts/events-staging-preflight.sh (same URL env as CI smoke).
// - Diagnostics: failure paths above should emit stable codes only via
//   logEventsDiagnostic (developer.log name `chisto.events`; no titles, ids, or queries).
//
// Performance budget (manual pass; mid-tier device, release build):
// - Feed: first meaningful frame after cold open (skeleton → list or empty state) within ~2s on Wi‑Fi.
// - Detail: hero + title visible within ~1.5s when event exists in list cache.
//
// -----------------------------------------------------------------------------
// 10) Known limitations (v1)
// -----------------------------------------------------------------------------
// - Filtered feed lists: disk snapshots are keyed by merged [EcoEventSearchParams]
//   (see EcoEventSearchParams.offlineListCacheSuffix); empty/global params still use the
//   legacy global key. Airplane mode shows the last successful snapshot for that key.
// - Search: the search field drives server `q=` on refresh; client-side filtering also
//   narrows the current in-memory list — see SearchEmptyState scope hint (ARB
//   eventsSearchEmptyScopeHint) when the query is non-trivial.
// - Detail refresh uses a TTL on resume (shorter while check-in is open or the event is
//   in progress); very rapid moderator edits may still lag until pull-to-refresh or re-entry.
// - Check-in: QR session rotation vs offline redeem queue ordering is covered by unit tests,
//   but extreme clock skew or multi-device races can still produce edge cases.
// - Chat outbox: at most [ChatOutboxStore.maxPendingTextRowsPerEvent] pending **text** rows
//   per event; when full, the UI shows eventsChatOutboxFull (connect and flush). SQLite v2 adds
//   `sync_status` / `attempt_count` / `last_error_code`; non-retryable sends mark `failed` for
//   hub visibility without opening chat. [EventChatScreen] flushes pending on socket connect;
//   [EventOfflineWorkCoordinator] also drains globally when online.
// - Field mode: `POST /events/field-batch` may partially succeed; mobile clears only rows
//   for applied indices (see field_mode_batch_result.dart). [FieldModeSyncService] shares the
//   POST + clear path with FieldModeScreen; auto-sync still runs on resume when online from the
//   screen; the coordinator also retries field batches after reconnect.
// - Cleanup evidence: large batches and backgrounding mid-upload depend on OS process limits;
//   back navigation is blocked while saving; a snack explains if the user tries to leave
//   (eventsEvidenceSaveInProgressHint).
// - Impact receipt share URL points at `{shareBase}/events/:id`; landing is implemented on
//   `apps/landing` (`/events/[id]`) with `GET /events/:id/share-card` (public). Rich OG tags remain
//   optional; see docs/events-release-checklist.md (universal links + AASA/assetlinks).
//
// Discovery funnel analytics (upgrade #3):
// - Mobile: [DiscoveryAnalytics] posts to `POST /discovery-analytics/events` when
//   `--dart-define=DISCOVERY_ANALYTICS_ENABLED=true` **and** user consent (`discovery_analytics_consent_v1`
//   in SharedPreferences via [DiscoveryAnalytics.setUserConsent]). Hook example: [EventsNavigation.openDetail].
// - API: ingest is a no-op unless env `DISCOVERY_ANALYTICS_ENABLED=true` (legal/ops gate); payload is
//   DTO-validated (event UUID, step enum, platform, appVersion) — no free-text, no GPS.
//
// Deferred epics (OS reminders, roster privacy, full warehouse dashboards):
// docs/events-deferred-epics.md (sign-off + API versioning expectations).
//
// Security / performance checklists:
// - docs/events-security-checklist.md
// - docs/events-performance-notes.md

// Events presentation conventions and implementation inventory.
//
// -----------------------------------------------------------------------------
// 1) Primary user journeys
// -----------------------------------------------------------------------------
// - Discovery journey:
//   EventsFeedScreen -> EventDetailScreen -> join/leave -> reminder -> share.
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
//
// -----------------------------------------------------------------------------
// 2) Mobile -> API surface matrix (current contracts)
// -----------------------------------------------------------------------------
// Events list/detail/lifecycle:
// - GET    /events?status=...&category=...&limit=...&cursor=...
//   (category: comma-separated mobile keys; status: comma-separated lifecycle keys)
// - GET    /events/:id
// - GET    /events/:id/participants?limit=...&cursor=...  (joiners only; organizer from detail)
// - POST   /events
// - PATCH  /events/:id
// - PATCH  /events/:id/status
// - PATCH  /events/:id/reminder
// - POST   /events/:id/join
// - DELETE /events/:id/join
// - POST   /events/:id/after-images
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
// Participant roster: ParticipantsSection loads joiners via EventsRepository.fetchParticipants
// (API: GET /events/:id/participants); checked-in badges on the sheet apply only to the
// current user (no inferred check-in state for other rows).
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
// 3c) Event detail section order (see DetailContent doc comment)
// -----------------------------------------------------------------------------
// Title → banners → EventDetailGroupedPanel → weather (if coords) → gear →
// description → participation → participants → organizer → analytics → after
// photos → impact. Stagger delays: event_detail_stagger.dart.
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
// - eventsDetailHeadline / eventsDetailScheduleLine: [TitleSection]
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
// -----------------------------------------------------------------------------
// 7) Create event screen (navigation + first paint)
// -----------------------------------------------------------------------------
// - Route: AppRoutes.eventsCreate uses CupertinoPageRoute (iOS edge swipe-back);
//   PopScope(canPop: !_isDirty) + onPopInvokedWithResult shows discard when needed.
// - First paint: short bootstrap skeleton (CreateEventScreenSkeleton) then
//   AnimatedSwitcher to form; section FadeTransitions respect reduce motion.
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
//   and optional scale/difficulty chips; rows use embedded* flags to avoid nested cards.
// - Title: status capsule uses [AppSpacing.radiusPill] + [AppTypography.pillLabel]-derived
//   styling; event name uses [AppTypography.eventsDetailHeadline] (theme headlineMedium).
//
// -----------------------------------------------------------------------------
// 9) Manual QA matrix (living checklist)
// -----------------------------------------------------------------------------
// - Reduced motion ON: staggered sections / pulse visuals
// - Large text + narrow width: event detail and organizer check-in overflow checks
// - Airplane mode: feed refresh, detail open, join/reminder/check-in feedback
// - Organizer pause/resume while screen is open: QR availability and banners
// - Attendee scanner: invalid/expired/wrong-event/rate-limit feedback paths
// - Participants sheet: loading, error+retry, organizer-only (count 0), multi-page fetch
// - Slow network: empty states, site picker, participant roster open from detail
// - Create event: Cupertino swipe-back vs dirty discard dialog; bootstrap skeleton timing
// - Optional API smoke: integration_test/events_journey_smoke_test.dart and
//   integration_test/event_chat_smoke_test.dart with --dart-define=API_URL and
//   INTEGRATION_TEST_ACCESS_TOKEN (see docs/events-release-hardening.md).
//
// Performance budget (manual pass; mid-tier device, release build):
// - Feed: first meaningful frame after cold open (skeleton → list or empty state) within ~2s on Wi‑Fi.
// - Detail: hero + title visible within ~1.5s when event exists in list cache.
//
// -----------------------------------------------------------------------------
// 10) Known limitations (v1)
// -----------------------------------------------------------------------------
// - Filtered feed lists (chips + sheet) are not guaranteed offline: disk cache may
//   hold only the last successful **unfiltered** global list; stale banner copy reflects that.
// - Client-side search narrows the **current** in-memory list; it does not always
//   imply a new server query (recent-search taps are local-only until debounced search fires).
// - Detail refresh uses a short TTL on resume; very rapid moderator edits may not appear
//   until pull-to-refresh or re-entry.
// - Check-in: QR session rotation vs offline redeem queue ordering is covered by unit tests,
//   but extreme clock skew or multi-device races can still produce edge cases.
// - Cleanup evidence: large batches and backgrounding mid-upload depend on OS process limits;
//   users should stay on-screen until save completes when uploading many photos.

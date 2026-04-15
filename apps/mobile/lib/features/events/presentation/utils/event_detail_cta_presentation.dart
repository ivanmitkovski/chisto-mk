import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Pure presentation for [StickyBottomCTA] — no Flutter imports (testable).
class EventDetailCtaPresentation {
  const EventDetailCtaPresentation({
    required this.primaryLabel,
    required this.primaryEnabled,
    required this.showsSecondaryRow,
    this.secondaryLabel,
  });

  final String primaryLabel;
  final bool primaryEnabled;

  /// When true, UI should stack a secondary outlined button under the primary.
  final bool showsSecondaryRow;
  final String? secondaryLabel;
}

/// Resolves labels and enabled flags from [event] and [l10n].
EventDetailCtaPresentation resolveEventDetailCtaPresentation({
  required EcoEvent event,
  required AppLocalizations l10n,
}) {
  if (event.isOrganizer) {
    return switch (event.status) {
      EcoEventStatus.upcoming when !event.moderationApproved => EventDetailCtaPresentation(
          primaryLabel: l10n.eventsAwaitingModerationCta,
          primaryEnabled: false,
          showsSecondaryRow: false,
        ),
      EcoEventStatus.upcoming => EventDetailCtaPresentation(
          primaryLabel: l10n.eventsCtaStartEvent,
          primaryEnabled: !event.isBeforeScheduledStart,
          showsSecondaryRow: false,
        ),
      EcoEventStatus.inProgress => EventDetailCtaPresentation(
          primaryLabel: l10n.eventsCtaManageCheckIn,
          primaryEnabled: true,
          showsSecondaryRow: false,
        ),
      EcoEventStatus.completed => EventDetailCtaPresentation(
          primaryLabel: event.hasAfterImages
              ? l10n.eventsCtaEditAfterPhotos
              : l10n.eventsCtaUploadAfterPhotos,
          primaryEnabled: true,
          showsSecondaryRow: false,
        ),
      _ => EventDetailCtaPresentation(
          primaryLabel: event.status.localizedLabel(l10n),
          primaryEnabled: false,
          showsSecondaryRow: false,
        ),
    };
  }

  if (event.status == EcoEventStatus.inProgress && event.isJoined) {
    if (event.isCheckedIn) {
      return EventDetailCtaPresentation(
        primaryLabel: l10n.eventsCtaCheckedIn,
        primaryEnabled: false,
        showsSecondaryRow: false,
      );
    }
    if (event.canOpenAttendeeCheckIn) {
      return EventDetailCtaPresentation(
        primaryLabel: l10n.eventsCtaScanToCheckIn,
        primaryEnabled: true,
        showsSecondaryRow: false,
      );
    }
    return EventDetailCtaPresentation(
      primaryLabel: l10n.eventsCtaCheckInPaused,
      primaryEnabled: false,
      showsSecondaryRow: false,
    );
  }

  if (event.isJoined) {
    return EventDetailCtaPresentation(
      primaryLabel: event.reminderEnabled
          ? l10n.eventsCtaTurnReminderOff
          : l10n.eventsCtaSetReminder,
      primaryEnabled: true,
      showsSecondaryRow: true,
      secondaryLabel: l10n.eventsCtaLeaveEvent,
    );
  }

  if (!event.moderationApproved) {
    return EventDetailCtaPresentation(
      primaryLabel: l10n.eventsEventPendingPublicCta,
      primaryEnabled: false,
      showsSecondaryRow: false,
    );
  }
  if (!event.isJoinable) {
    return EventDetailCtaPresentation(
      primaryLabel: event.status.localizedLabel(l10n),
      primaryEnabled: false,
      showsSecondaryRow: false,
    );
  }
  return EventDetailCtaPresentation(
    primaryLabel: l10n.eventsCtaJoinEcoAction,
    primaryEnabled: true,
    showsSecondaryRow: false,
  );
}

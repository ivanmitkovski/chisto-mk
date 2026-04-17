import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_detail_cta_presentation.dart';
import 'package:chisto_mobile/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();

  EcoEvent base({
    required String id,
    required EcoEventStatus status,
    required String organizerId,
    bool isJoined = false,
    bool moderationApproved = true,
    bool isCheckInOpen = false,
    AttendeeCheckInStatus attendeeCheckInStatus =
        AttendeeCheckInStatus.notCheckedIn,
  }) {
    return EcoEvent(
      id: id,
      title: 'T',
      description: 'D',
      category: EcoEventCategory.generalCleanup,
      siteId: 's',
      siteName: 'Site',
      siteImageUrl: '',
      siteDistanceKm: 1,
      organizerId: organizerId,
      organizerName: 'Org',
      date: DateTime(2026, 6, 1),
      startTime: const EventTime(hour: 10, minute: 0),
      endTime: const EventTime(hour: 11, minute: 0),
      participantCount: 2,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      isJoined: isJoined,
      moderationApproved: moderationApproved,
      isCheckInOpen: isCheckInOpen,
      attendeeCheckInStatus: attendeeCheckInStatus,
    );
  }

  test('joinable public guest: primary enabled, no secondary row', () {
    final EcoEvent event = base(
      id: '1',
      status: EcoEventStatus.upcoming,
      organizerId: 'other',
      isJoined: false,
    ).copyWith(scheduledAtUtc: DateTime.utc(2020, 6, 1, 8, 0));
    final EventDetailCtaPresentation p =
        resolveEventDetailCtaPresentation(event: event, l10n: l10n);
    expect(p.primaryEnabled, isTrue);
    expect(p.showsSecondaryRow, isFalse);
    expect(p.primaryLabel, l10n.eventsCtaJoinEcoAction);
  });

  test('joinable guest before scheduled start: Join disabled', () {
    final EcoEvent event = base(
      id: 'join-future',
      status: EcoEventStatus.upcoming,
      organizerId: 'other',
      isJoined: false,
    ).copyWith(scheduledAtUtc: DateTime.utc(2035, 6, 1, 8, 0));
    final EventDetailCtaPresentation p =
        resolveEventDetailCtaPresentation(event: event, l10n: l10n);
    expect(p.primaryLabel, l10n.eventsCtaJoinEcoAction);
    expect(p.primaryEnabled, isFalse);
    expect(p.showsSecondaryRow, isFalse);
  });

  test('joined upcoming: reminder primary and leave secondary', () {
    final EcoEvent event = base(
      id: '2',
      status: EcoEventStatus.upcoming,
      organizerId: 'other',
      isJoined: true,
    );
    final EventDetailCtaPresentation p =
        resolveEventDetailCtaPresentation(event: event, l10n: l10n);
    expect(p.primaryEnabled, isTrue);
    expect(p.showsSecondaryRow, isTrue);
    expect(p.secondaryLabel, l10n.eventsCtaLeaveEvent);
  });

  test('organizer upcoming before scheduled start: start disabled', () {
    final EcoEvent event = base(
      id: 'org-future',
      status: EcoEventStatus.upcoming,
      organizerId: 'current_user',
    ).copyWith(scheduledAtUtc: DateTime.utc(2035, 6, 1, 9, 0));
    final EventDetailCtaPresentation p =
        resolveEventDetailCtaPresentation(event: event, l10n: l10n);
    expect(p.primaryLabel, l10n.eventsCtaStartEvent);
    expect(p.primaryEnabled, isFalse);
  });

  test('organizer in progress: manage check-in primary and extend secondary', () {
    final EcoEvent event = base(
      id: 'org-live',
      status: EcoEventStatus.inProgress,
      organizerId: 'current_user',
    );
    final EventDetailCtaPresentation p =
        resolveEventDetailCtaPresentation(event: event, l10n: l10n);
    expect(p.primaryLabel, l10n.eventsCtaManageCheckIn);
    expect(p.primaryEnabled, isTrue);
    expect(p.showsSecondaryRow, isTrue);
    expect(p.secondaryIsExtendCleanupEnd, isTrue);
    expect(p.secondaryLabel, l10n.eventsCtaExtendCleanupEnd);
  });

  test('organizer upcoming after scheduled start: start enabled', () {
    final EcoEvent event = base(
      id: 'org-past',
      status: EcoEventStatus.upcoming,
      organizerId: 'current_user',
    ).copyWith(scheduledAtUtc: DateTime.utc(2020, 6, 1, 9, 0));
    final EventDetailCtaPresentation p =
        resolveEventDetailCtaPresentation(event: event, l10n: l10n);
    expect(p.primaryLabel, l10n.eventsCtaStartEvent);
    expect(p.primaryEnabled, isTrue);
  });

  test('cancelled event with isJoined does not show leave/reminder CTA', () {
    final EcoEvent event = base(
      id: 'cancelled-joined',
      status: EcoEventStatus.cancelled,
      organizerId: 'other',
      isJoined: true,
    );
    final EventDetailCtaPresentation p =
        resolveEventDetailCtaPresentation(event: event, l10n: l10n);
    expect(p.primaryEnabled, isFalse);
    expect(p.showsSecondaryRow, isFalse);
  });

  test('completed event with isJoined does not show leave/reminder CTA', () {
    final EcoEvent event = base(
      id: 'completed-joined',
      status: EcoEventStatus.completed,
      organizerId: 'other',
      isJoined: true,
    );
    final EventDetailCtaPresentation p =
        resolveEventDetailCtaPresentation(event: event, l10n: l10n);
    expect(p.primaryEnabled, isFalse);
    expect(p.showsSecondaryRow, isFalse);
  });
}

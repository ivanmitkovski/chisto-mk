import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:chisto_infrastructure/shared/current_user.dart';
import 'package:feature_events/src/domain/models/eco_event_enums.dart';
import 'package:feature_events/src/domain/models/event_pulse_route_evidence.dart';
import 'package:meta/meta.dart';

export 'package:feature_events/src/domain/models/eco_event_enums.dart';

@immutable
class EventTime {
  const EventTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;

  String get formatted =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTime && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'EventTime($formatted)';
}

@immutable
class EcoEvent {
  const EcoEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.siteId,
    required this.siteName,
    required this.siteImageUrl,
    required this.siteDistanceKm,
    required this.organizerId,
    required this.organizerName,
    this.organizerIsDeleted = false,
    this.organizerAvatarUrl,
    required this.date,

    /// Local calendar date of [endTime]. When null, end is on [date] (legacy same-day).
    this.endDate,
    required this.startTime,
    required this.endTime,
    required this.participantCount,
    required this.status,
    required this.createdAt,
    this.maxParticipants,
    this.isJoined = false,
    this.activeCheckInSessionId,
    this.isCheckInOpen = false,
    this.checkedInCount = 0,
    this.attendeeCheckInStatus = AttendeeCheckInStatus.notCheckedIn,
    this.attendeeCheckedInAt,
    this.reminderEnabled = false,
    this.reminderAt,
    this.afterImagePaths = const <String>[],
    this.gear = const <EventGear>[],
    this.scale,
    this.difficulty,

    /// Default false: only explicit server `moderationApproved: true` means published.
    this.moderationApproved = false,
    this.moderationStatus = ModerationStatus.pending,
    this.siteLat,
    this.siteLng,
    this.recurrenceRule,
    this.parentEventId,
    this.recurrenceIndex,
    this.scheduledAtUtc,
    this.recurrenceSeriesTotal,
    this.recurrenceSeriesPosition,
    this.recurrencePrevEventId,
    this.recurrenceNextEventId,
    this.routeSegments = const <EventRouteSegmentModel>[],
    this.evidenceStrip = const <EventEvidenceStripItem>[],
    this.liveReportedBagsCollected = 0,
    this.liveMetricUpdatedAt,
  });

  factory EcoEvent.fromJson(Map<String, dynamic> json) {
    T enumByNameOr<T extends Enum>(List<T> values, String? name, T fallback) {
      if (name == null) return fallback;
      for (final T value in values) {
        if (value.name == name) return value;
      }
      assert(() {
        AppLog.verbose(
          '[EcoEvent] Unknown enum value "$name" for '
          '${fallback.runtimeType}, falling back to ${fallback.name}',
        );
        return true;
      }(), 'Logs unknown enum fallbacks in debug builds only');
      return fallback;
    }

    EventTime decodeTime(dynamic raw, EventTime fallback) {
      if (raw is Map<String, dynamic>) {
        final int hour = (raw['hour'] as num?)?.toInt() ?? fallback.hour;
        final int minute = (raw['minute'] as num?)?.toInt() ?? fallback.minute;
        return EventTime(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
      }
      return fallback;
    }

    DateTime parseDate(dynamic raw, DateTime fallback) {
      if (raw is String) {
        final DateTime? parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          return parsed;
        }
      }
      return fallback;
    }

    final DateTime now = DateTime.now();
    final DateTime eventDate = parseDate(json['date'], now);
    DateTime dayOnlyD(DateTime d) => DateTime(d.year, d.month, d.day);
    final DateTime startDay = dayOnlyD(eventDate);
    DateTime? computedEndDate;
    if (json['endDate'] is String) {
      final DateTime parsed = parseDate(json['endDate'], now);
      final DateTime ed = dayOnlyD(parsed);
      if (ed.isAfter(startDay)) {
        computedEndDate = ed;
      }
    } else {
      final String? endAtStr = json['endAt'] as String?;
      if (endAtStr != null) {
        final DateTime? endAtLocal = DateTime.tryParse(endAtStr)?.toLocal();
        if (endAtLocal != null) {
          final DateTime endDay = dayOnlyD(endAtLocal);
          if (endDay.isAfter(startDay)) {
            computedEndDate = endDay;
          }
        }
      }
    }
    return EcoEvent(
      id: (json['id'] as String?) ?? 'evt-${now.millisecondsSinceEpoch}',
      title: (json['title'] as String?) ?? 'Untitled event',
      description: (json['description'] as String?) ?? '',
      category: enumByNameOr<EcoEventCategory>(
        EcoEventCategory.values,
        json['category'] as String?,
        EcoEventCategory.generalCleanup,
      ),
      siteId: (json['siteId'] as String?) ?? '',
      siteName: (json['siteName'] as String?) ?? '',
      siteImageUrl: (json['siteImageUrl'] as String?) ?? '',
      siteDistanceKm: (json['siteDistanceKm'] as num?)?.toDouble() ?? 0,
      organizerId: (json['organizerId'] as String?) ?? '',
      organizerName: (json['organizerName'] as String?) ?? '',
      organizerIsDeleted: json['organizerIsDeleted'] as bool? ?? false,
      organizerAvatarUrl: json['organizerAvatarUrl'] as String?,
      date: eventDate,
      endDate: computedEndDate,
      startTime: decodeTime(
        json['startTime'],
        const EventTime(hour: 10, minute: 0),
      ),
      endTime: decodeTime(
        json['endTime'],
        const EventTime(hour: 12, minute: 0),
      ),
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
      status: enumByNameOr<EcoEventStatus>(
        EcoEventStatus.values,
        json['status'] as String?,
        EcoEventStatus.upcoming,
      ),
      createdAt: parseDate(json['createdAt'], now),
      isJoined: (json['isJoined'] as bool?) ?? false,
      activeCheckInSessionId: json['activeCheckInSessionId'] as String?,
      isCheckInOpen: (json['isCheckInOpen'] as bool?) ?? false,
      checkedInCount: (json['checkedInCount'] as num?)?.toInt() ?? 0,
      attendeeCheckInStatus: enumByNameOr<AttendeeCheckInStatus>(
        AttendeeCheckInStatus.values,
        json['attendeeCheckInStatus'] as String?,
        AttendeeCheckInStatus.notCheckedIn,
      ),
      attendeeCheckedInAt: json['attendeeCheckedInAt'] == null
          ? null
          : parseDate(json['attendeeCheckedInAt'], now).toLocal(),
      reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
      reminderAt: json['reminderAt'] == null
          ? null
          : parseDate(json['reminderAt'], now).toLocal(),
      afterImagePaths:
          (safeAsList(json['afterImagePaths']) ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      gear: (safeAsList(json['gear']) ?? const <dynamic>[])
          .whereType<String>()
          .map(
            (String raw) => enumByNameOr<EventGear>(
              EventGear.values,
              raw,
              EventGear.trashBags,
            ),
          )
          .toSet()
          .toList(growable: false),
      scale: json['scale'] == null
          ? null
          : enumByNameOr<CleanupScale>(
              CleanupScale.values,
              json['scale'] as String?,
              CleanupScale.small,
            ),
      difficulty: json['difficulty'] == null
          ? null
          : enumByNameOr<EventDifficulty>(
              EventDifficulty.values,
              json['difficulty'] as String?,
              EventDifficulty.easy,
            ),
      // Fail closed: absent or non-bool must not be treated as approved (stale cache / older payloads).
      moderationApproved: json['moderationApproved'] == true,
      moderationStatus: ModerationStatus.fromBoolAndString(
        moderationApproved: json['moderationApproved'] == true,
        moderationStatusRaw: json['moderationStatus'] as String?,
      ),
      siteLat: (json['siteLat'] as num?)?.toDouble(),
      siteLng: (json['siteLng'] as num?)?.toDouble(),
      recurrenceRule: json['recurrenceRule'] as String?,
      parentEventId: json['parentEventId'] as String?,
      recurrenceIndex: (json['recurrenceIndex'] as num?)?.toInt(),
      recurrenceSeriesTotal: (json['recurrenceSeriesTotal'] as num?)?.toInt(),
      recurrenceSeriesPosition: (json['recurrenceSeriesPosition'] as num?)
          ?.toInt(),
      recurrencePrevEventId: json['recurrencePrevEventId'] as String?,
      recurrenceNextEventId: json['recurrenceNextEventId'] as String?,
      scheduledAtUtc: () {
        final String? iso =
            json['scheduledAtUtc'] as String? ?? json['scheduledAt'] as String?;
        if (iso == null) return null;
        final DateTime? parsed = DateTime.tryParse(iso);
        return parsed?.toUtc();
      }(),
      routeSegments: (safeAsList(json['routeSegments']) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(EventRouteSegmentModel.fromJson)
          .toList(growable: false),
      evidenceStrip: (safeAsList(json['evidenceStrip']) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(EventEvidenceStripItem.fromJson)
          .toList(growable: false),
      liveReportedBagsCollected:
          (json['liveReportedBagsCollected'] as num?)?.toInt() ?? 0,
      liveMetricUpdatedAt: json['liveMetricUpdatedAt'] == null
          ? null
          : DateTime.tryParse(json['liveMetricUpdatedAt'] as String),
    );
  }

  final String id;
  final String title;
  final String description;
  final EcoEventCategory category;
  final String siteId;
  final String siteName;
  final String siteImageUrl;
  final double siteDistanceKm;

  /// Geographic latitude of the cleanup site (from API). Null when not exposed.
  final double? siteLat;

  /// Geographic longitude of the cleanup site (from API). Null when not exposed.
  final double? siteLng;

  /// RFC 5545 RRULE string. Null for non-recurring events.
  final String? recurrenceRule;

  /// ID of the first event in a recurring series. Null for standalone / parent events.
  final String? parentEventId;

  /// 0-based position in the series (0 = parent/original). Null for non-recurring.
  final int? recurrenceIndex;

  /// Number of events in the recurring series (same root), from API. Null when not a series.
  final int? recurrenceSeriesTotal;

  /// 1-based position in the series by [scheduledAt] order, from API.
  final int? recurrenceSeriesPosition;

  /// Previous occurrence in the series (by scheduled time), when present.
  final String? recurrencePrevEventId;

  /// Next occurrence in the series (by scheduled time), when present.
  final String? recurrenceNextEventId;

  /// When the event starts in UTC (from API `scheduledAt`). Used for timezone-aware helpers.
  final DateTime? scheduledAtUtc;

  bool get isRecurring => recurrenceRule != null && recurrenceRule!.isNotEmpty;
  final String organizerId;
  final String organizerName;
  final bool organizerIsDeleted;
  final String? organizerAvatarUrl;
  final DateTime date;
  final DateTime? endDate;
  final EventTime startTime;
  final EventTime endTime;
  final int participantCount;
  final int? maxParticipants;
  final EcoEventStatus status;
  final bool isJoined;
  final String? activeCheckInSessionId;
  final bool isCheckInOpen;
  final int checkedInCount;
  final AttendeeCheckInStatus attendeeCheckInStatus;
  final DateTime? attendeeCheckedInAt;
  final bool reminderEnabled;
  final DateTime? reminderAt;
  final List<String> afterImagePaths;
  final DateTime createdAt;
  final List<EventGear> gear;
  final CleanupScale? scale;
  final EventDifficulty? difficulty;

  /// Server moderation: true only when [CleanupEvent] is APPROVED. Constructor defaults to false;
  /// [EcoEvent.fromJson] sets true only when JSON contains `moderationApproved: true`.
  final bool moderationApproved;

  /// Rich 3-state moderation lifecycle from API `moderationStatus` field.
  /// Falls back to [moderationApproved] boolean when the API field is absent.
  final ModerationStatus moderationStatus;

  bool get isDeclined => moderationStatus == ModerationStatus.declined;

  final List<EventRouteSegmentModel> routeSegments;
  final List<EventEvidenceStripItem> evidenceStrip;
  final int liveReportedBagsCollected;
  final DateTime? liveMetricUpdatedAt;

  /// After the scheduled start instant, volunteers may still join for this duration.
  static const Duration volunteerJoinGraceAfterStart = Duration(minutes: 15);

  bool get isOrganizer => organizerId == CurrentUser.id;
  bool get isJoinable =>
      !isOrganizer &&
      moderationApproved &&
      status != EcoEventStatus.completed &&
      status != EcoEventStatus.cancelled;

  bool get _isBeforeVolunteerJoinDeadline {
    final DateTime? utc = scheduledAtUtc;
    if (utc != null) {
      return DateTime.now().toUtc().isBefore(
        utc.add(volunteerJoinGraceAfterStart),
      );
    }
    return DateTime.now().isBefore(
      startDateTime.add(volunteerJoinGraceAfterStart),
    );
  }

  /// New joins allowed until scheduled start + [volunteerJoinGraceAfterStart].
  bool get canVolunteerJoinNow => isJoinable && _isBeforeVolunteerJoinDeadline;

  /// Volunteer-facing join is closed while the event may still show API status `upcoming`.
  bool get isVolunteerJoinClosed =>
      !isOrganizer && !isJoined && isJoinable && !canVolunteerJoinNow;

  /// Past for discovery lists: completed/cancelled, or join window closed for guests.
  bool get isPastForPublicDiscovery =>
      status == EcoEventStatus.completed ||
      status == EcoEventStatus.cancelled ||
      (status == EcoEventStatus.upcoming &&
          !isOrganizer &&
          !isJoined &&
          !canVolunteerJoinNow);

  /// Rebuild join CTA periodically near the join cutoff or when the start is soon.
  bool get shouldTickVolunteerJoinNearDeadline {
    if (!isJoinable || isJoined || isOrganizer) {
      return false;
    }
    if (!_isBeforeVolunteerJoinDeadline) {
      return false;
    }
    const Duration horizon = Duration(hours: 3);
    final DateTime? utc = scheduledAtUtc;
    if (utc != null) {
      final DateTime now = DateTime.now().toUtc();
      final DateTime deadline = utc.add(volunteerJoinGraceAfterStart);
      final Duration untilClose = deadline.difference(now);
      if (untilClose <= horizon) {
        return true;
      }
      final Duration untilStart = utc.difference(now);
      return !untilStart.isNegative && untilStart <= horizon;
    }
    final DateTime now = DateTime.now();
    final DateTime deadline = startDateTime.add(volunteerJoinGraceAfterStart);
    final Duration untilClose = deadline.difference(now);
    if (untilClose <= horizon) {
      return true;
    }
    final Duration untilStart = startDateTime.difference(now);
    return !untilStart.isNegative && untilStart <= horizon;
  }

  bool get isLifecycleClosed =>
      status == EcoEventStatus.completed || status == EcoEventStatus.cancelled;
  bool get isCheckedIn =>
      attendeeCheckInStatus == AttendeeCheckInStatus.checkedIn;
  bool get hasAfterImages => afterImagePaths.isNotEmpty;
  bool get canOpenAttendeeCheckIn =>
      moderationApproved &&
      isJoined &&
      !isOrganizer &&
      status == EcoEventStatus.inProgress &&
      isCheckInOpen;

  /// True while the scheduled start instant is still in the future (organizer must wait).
  bool get isBeforeScheduledStart {
    final DateTime? utc = scheduledAtUtc;
    if (utc != null) {
      return DateTime.now().toUtc().isBefore(utc);
    }
    return DateTime.now().isBefore(startDateTime);
  }

  bool canTransitionTo(EcoEventStatus next) {
    if (status == next) {
      return true;
    }
    switch (status) {
      case EcoEventStatus.upcoming:
        return next == EcoEventStatus.inProgress ||
            next == EcoEventStatus.cancelled;
      case EcoEventStatus.inProgress:
        return next == EcoEventStatus.completed ||
            next == EcoEventStatus.cancelled;
      case EcoEventStatus.completed:
      case EcoEventStatus.cancelled:
        return false;
    }
  }

  static bool isValidRange(EventTime start, EventTime end) =>
      end.totalMinutes > start.totalMinutes;

  DateTime get _endCalendarDay =>
      endDate ?? DateTime(date.year, date.month, date.day);

  bool get spansMultipleCalendarDays {
    final DateTime startDay = DateTime(date.year, date.month, date.day);
    final DateTime endDay = DateTime(
      _endCalendarDay.year,
      _endCalendarDay.month,
      _endCalendarDay.day,
    );
    return endDay.isAfter(startDay);
  }

  String get formattedTimeRange {
    if (spansMultipleCalendarDays) {
      final DateTime ed = _endCalendarDay;
      return '${startTime.formatted} – ${endTime.formatted} '
          '(${ed.day.toString().padLeft(2, '0')}.${ed.month.toString().padLeft(2, '0')})';
    }
    return '${startTime.formatted} - ${endTime.formatted}';
  }

  DateTime get startDateTime => DateTime(
    date.year,
    date.month,
    date.day,
    startTime.hour,
    startTime.minute,
  );

  DateTime get endDateTime => DateTime(
    _endCalendarDay.year,
    _endCalendarDay.month,
    _endCalendarDay.day,
    endTime.hour,
    endTime.minute,
  );

  EcoEvent copyWith({
    String? title,
    String? description,
    EcoEventCategory? category,
    String? siteId,
    String? siteName,
    String? siteImageUrl,
    double? siteDistanceKm,
    String? organizerAvatarUrl,
    bool clearOrganizerAvatarUrl = false,
    DateTime? date,
    DateTime? endDate,
    bool clearEndDate = false,
    EventTime? startTime,
    EventTime? endTime,
    int? participantCount,
    int? maxParticipants,
    bool clearMaxParticipants = false,
    EcoEventStatus? status,
    bool? isJoined,
    String? activeCheckInSessionId,
    bool clearActiveCheckInSessionId = false,
    bool? isCheckInOpen,
    int? checkedInCount,
    AttendeeCheckInStatus? attendeeCheckInStatus,
    DateTime? attendeeCheckedInAt,
    bool clearAttendeeCheckedInAt = false,
    bool? reminderEnabled,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    List<String>? afterImagePaths,
    List<EventGear>? gear,
    CleanupScale? scale,
    bool clearScale = false,
    EventDifficulty? difficulty,
    bool clearDifficulty = false,
    bool? moderationApproved,
    ModerationStatus? moderationStatus,
    DateTime? scheduledAtUtc,
    int? recurrenceSeriesTotal,
    int? recurrenceSeriesPosition,
    String? recurrencePrevEventId,
    String? recurrenceNextEventId,
    bool clearRecurrenceNav = false,
  }) {
    return EcoEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      siteImageUrl: siteImageUrl ?? this.siteImageUrl,
      siteDistanceKm: siteDistanceKm ?? this.siteDistanceKm,
      organizerId: organizerId,
      organizerName: organizerName,
      organizerIsDeleted: organizerIsDeleted,
      organizerAvatarUrl: clearOrganizerAvatarUrl
          ? null
          : organizerAvatarUrl ?? this.organizerAvatarUrl,
      date: date ?? this.date,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: clearMaxParticipants
          ? null
          : maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      isJoined: isJoined ?? this.isJoined,
      activeCheckInSessionId: clearActiveCheckInSessionId
          ? null
          : activeCheckInSessionId ?? this.activeCheckInSessionId,
      isCheckInOpen: isCheckInOpen ?? this.isCheckInOpen,
      checkedInCount: checkedInCount ?? this.checkedInCount,
      attendeeCheckInStatus:
          attendeeCheckInStatus ?? this.attendeeCheckInStatus,
      attendeeCheckedInAt: clearAttendeeCheckedInAt
          ? null
          : attendeeCheckedInAt ?? this.attendeeCheckedInAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderAt: clearReminderAt ? null : reminderAt ?? this.reminderAt,
      afterImagePaths: afterImagePaths ?? this.afterImagePaths,
      createdAt: createdAt,
      gear: gear ?? this.gear,
      scale: clearScale ? null : scale ?? this.scale,
      difficulty: clearDifficulty ? null : difficulty ?? this.difficulty,
      moderationApproved: moderationApproved ?? this.moderationApproved,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      siteLat: siteLat,
      siteLng: siteLng,
      recurrenceRule: recurrenceRule,
      parentEventId: parentEventId,
      recurrenceIndex: recurrenceIndex,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      recurrenceSeriesTotal:
          recurrenceSeriesTotal ?? this.recurrenceSeriesTotal,
      recurrenceSeriesPosition:
          recurrenceSeriesPosition ?? this.recurrenceSeriesPosition,
      recurrencePrevEventId: clearRecurrenceNav
          ? null
          : recurrencePrevEventId ?? this.recurrencePrevEventId,
      recurrenceNextEventId: clearRecurrenceNav
          ? null
          : recurrenceNextEventId ?? this.recurrenceNextEventId,
      routeSegments: routeSegments,
      evidenceStrip: evidenceStrip,
      liveReportedBagsCollected: liveReportedBagsCollected,
      liveMetricUpdatedAt: liveMetricUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EcoEvent &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          category == other.category &&
          siteId == other.siteId &&
          status == other.status &&
          isJoined == other.isJoined &&
          participantCount == other.participantCount &&
          checkedInCount == other.checkedInCount &&
          isCheckInOpen == other.isCheckInOpen &&
          attendeeCheckInStatus == other.attendeeCheckInStatus &&
          reminderEnabled == other.reminderEnabled &&
          date == other.date &&
          endDate == other.endDate &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          scheduledAtUtc == other.scheduledAtUtc &&
          chistoListEquals(afterImagePaths, other.afterImagePaths) &&
          chistoListEquals(gear, other.gear) &&
          moderationApproved == other.moderationApproved &&
          moderationStatus == other.moderationStatus &&
          liveReportedBagsCollected == other.liveReportedBagsCollected &&
          liveMetricUpdatedAt == other.liveMetricUpdatedAt &&
          chistoListEquals(routeSegments, other.routeSegments) &&
          chistoListEquals(evidenceStrip, other.evidenceStrip);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    category,
    siteId,
    status,
    isJoined,
    participantCount,
    checkedInCount,
    isCheckInOpen,
    attendeeCheckInStatus,
    reminderEnabled,
    date,
    endDate,
    startTime,
    endTime,
    scheduledAtUtc,
    Object.hash(
      Object.hashAll(afterImagePaths),
      Object.hashAll(gear),
      moderationApproved,
      moderationStatus,
      liveReportedBagsCollected,
      liveMetricUpdatedAt,
      Object.hashAll(routeSegments),
      Object.hashAll(evidenceStrip),
    ),
  );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'siteId': siteId,
      'siteName': siteName,
      'siteImageUrl': siteImageUrl,
      'siteDistanceKm': siteDistanceKm,
      if (siteLat != null) 'siteLat': siteLat,
      if (siteLng != null) 'siteLng': siteLng,
      if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
      if (parentEventId != null) 'parentEventId': parentEventId,
      if (recurrenceIndex != null) 'recurrenceIndex': recurrenceIndex,
      if (recurrenceSeriesTotal != null)
        'recurrenceSeriesTotal': recurrenceSeriesTotal,
      if (recurrenceSeriesPosition != null)
        'recurrenceSeriesPosition': recurrenceSeriesPosition,
      if (recurrencePrevEventId != null)
        'recurrencePrevEventId': recurrencePrevEventId,
      if (recurrenceNextEventId != null)
        'recurrenceNextEventId': recurrenceNextEventId,
      if (scheduledAtUtc != null)
        'scheduledAtUtc': scheduledAtUtc!.toUtc().toIso8601String(),
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerIsDeleted': organizerIsDeleted,
      if (organizerAvatarUrl != null) 'organizerAvatarUrl': organizerAvatarUrl,
      'date': date.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'startTime': <String, int>{
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': <String, int>{'hour': endTime.hour, 'minute': endTime.minute},
      'participantCount': participantCount,
      'maxParticipants': maxParticipants,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'isJoined': isJoined,
      'activeCheckInSessionId': activeCheckInSessionId,
      'isCheckInOpen': isCheckInOpen,
      'checkedInCount': checkedInCount,
      'attendeeCheckInStatus': attendeeCheckInStatus.name,
      'attendeeCheckedInAt': attendeeCheckedInAt?.toIso8601String(),
      'reminderEnabled': reminderEnabled,
      'reminderAt': reminderAt?.toIso8601String(),
      'afterImagePaths': afterImagePaths,
      'gear': gear.map((EventGear g) => g.name).toList(growable: false),
      'scale': scale?.name,
      'difficulty': difficulty?.name,
      'moderationApproved': moderationApproved,
      'moderationStatus': moderationStatus.name,
      'routeSegments': routeSegments
          .map(
            (EventRouteSegmentModel s) => <String, dynamic>{
              'id': s.id,
              'sortOrder': s.sortOrder,
              'label': s.label,
              'latitude': s.latitude,
              'longitude': s.longitude,
              'status': s.status,
              'claimedByUserId': s.claimedByUserId,
              'claimedAt': s.claimedAt?.toIso8601String(),
              'completedAt': s.completedAt?.toIso8601String(),
            },
          )
          .toList(growable: false),
      'evidenceStrip': evidenceStrip
          .map(
            (EventEvidenceStripItem e) => <String, dynamic>{
              'id': e.id,
              'kind': e.kind,
              'imageUrl': e.imageUrl,
              'caption': e.caption,
              'createdAt': e.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'liveReportedBagsCollected': liveReportedBagsCollected,
      if (liveMetricUpdatedAt != null)
        'liveMetricUpdatedAt': liveMetricUpdatedAt!.toIso8601String(),
    };
  }
}

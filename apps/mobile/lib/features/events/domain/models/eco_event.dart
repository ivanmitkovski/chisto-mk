import 'package:chisto_mobile/shared/current_user.dart';
import 'package:flutter/foundation.dart';

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

enum EcoEventCategory {
  generalCleanup(
    'General cleanup',
    'Pick up litter, sweep debris, and restore the area.',
    0xf643,
  ),
  riverAndLake(
    'River & lake cleanup',
    'Remove waste from waterways, shores, and drainage channels.',
    0xf02a6,
  ),
  treeAndGreen(
    'Tree planting & greening',
    'Plant trees, restore green spaces, and build garden beds.',
    0xf004e,
  ),
  recyclingDrive(
    'Recycling drive',
    'Sort, collect, and transport recyclables to processing centers.',
    0xf0370,
  ),
  hazardousRemoval(
    'Hazardous waste removal',
    'Safely collect chemicals, tires, batteries, or asbestos.',
    0xf02a0,
  ),
  awarenessAndEducation(
    'Awareness & education',
    'Workshops, talks, or community engagement on eco practices.',
    0xf012e,
  ),
  other(
    'Other',
    'Custom event that doesn\'t match the categories above.',
    0xf8d9,
  );

  const EcoEventCategory(this.label, this.description, this.iconCodePoint);
  final String label;
  final String description;
  final int iconCodePoint;

  /// The camelCase key sent to/received from the API `category` query param.
  String get key => name;
}

enum EventGear {
  trashBags('Trash bags', 0xf37d),
  gloves('Gloves', 0xf05c0),
  rakes('Rakes & shovels', 0xf7be),
  wheelbarrow('Wheelbarrow', 0xf06f2),
  waterBoots('Water boots', 0xefde),
  safetyVest('Safety vest', 0xf379),
  firstAid('First aid kit', 0xf1be),
  sunscreen('Sunscreen & water', 0xf4bc);

  const EventGear(this.label, this.iconCodePoint);
  final String label;
  final int iconCodePoint;
}

enum CleanupScale {
  small('Small (1–5 people)', 'Quick spot cleanup, one bag or two.'),
  medium('Medium (6–15 people)', 'Half-day effort, several areas covered.'),
  large('Large (16–40 people)', 'Organized group, heavy waste removal.'),
  massive('Massive (40+ people)', 'City-wide or multi-site event.');

  const CleanupScale(this.label, this.description);
  final String label;
  final String description;
}

enum EventDifficulty {
  easy('Easy', 'Flat terrain, light waste, family-friendly.', 0xFF2FD788),
  moderate('Moderate', 'Mixed terrain or bulky items, some effort.', 0xFFF5A623),
  hard('Hard', 'Steep slopes, heavy debris, or hazardous materials.', 0xFFE6513D);

  const EventDifficulty(this.label, this.description, this.colorValue);
  final String label;
  final String description;
  final int colorValue;
}

enum EcoEventStatus {
  upcoming('Upcoming', 0xFF2FD788),
  inProgress('In progress', 0xFF3BA3F7),
  completed('Completed', 0xFF7A7A7A),
  cancelled('Cancelled', 0xFFE6513D);

  const EcoEventStatus(this.label, this.colorValue);
  final String label;
  final int colorValue;

  /// The camelCase lifecycle key accepted by the `status=` query param.
  String get apiKey => name;
}

enum AttendeeCheckInStatus {
  notCheckedIn,
  checkedIn,
}

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
    this.organizerAvatarUrl,
    required this.date,
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
    this.moderationApproved = true,
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
  });

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
  final String? organizerAvatarUrl;
  final DateTime date;
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

  /// Server moderation: citizen-created events are false until [CleanupEvent] is APPROVED.
  final bool moderationApproved;

  bool get isOrganizer => organizerId == CurrentUser.id;
  bool get isJoinable =>
      !isOrganizer &&
      moderationApproved &&
      status != EcoEventStatus.completed &&
      status != EcoEventStatus.cancelled;

  /// New joins allowed (server: not before [scheduledAtUtc] / [startDateTime]).
  bool get canVolunteerJoinNow => isJoinable && !isBeforeScheduledStart;

  bool get isLifecycleClosed =>
      status == EcoEventStatus.completed || status == EcoEventStatus.cancelled;
  bool get isCheckedIn => attendeeCheckInStatus == AttendeeCheckInStatus.checkedIn;
  bool get hasAfterImages => afterImagePaths.isNotEmpty;
  bool get canOpenAttendeeCheckIn =>
      isJoined && !isOrganizer && status == EcoEventStatus.inProgress && isCheckInOpen;

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
        return next == EcoEventStatus.inProgress || next == EcoEventStatus.cancelled;
      case EcoEventStatus.inProgress:
        return next == EcoEventStatus.completed || next == EcoEventStatus.cancelled;
      case EcoEventStatus.completed:
      case EcoEventStatus.cancelled:
        return false;
    }
  }

  static bool isValidRange(EventTime start, EventTime end) =>
      end.totalMinutes > start.totalMinutes;

  String get formattedTimeRange => '${startTime.formatted} - ${endTime.formatted}';

  DateTime get startDateTime => DateTime(
        date.year, date.month, date.day,
        startTime.hour, startTime.minute,
      );

  DateTime get endDateTime => DateTime(
        date.year, date.month, date.day,
        endTime.hour, endTime.minute,
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
      organizerAvatarUrl: clearOrganizerAvatarUrl
          ? null
          : organizerAvatarUrl ?? this.organizerAvatarUrl,
      date: date ?? this.date,
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
      siteLat: siteLat,
      siteLng: siteLng,
      recurrenceRule: recurrenceRule,
      parentEventId: parentEventId,
      recurrenceIndex: recurrenceIndex,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      recurrenceSeriesTotal: recurrenceSeriesTotal ?? this.recurrenceSeriesTotal,
      recurrenceSeriesPosition:
          recurrenceSeriesPosition ?? this.recurrenceSeriesPosition,
      recurrencePrevEventId: clearRecurrenceNav
          ? null
          : recurrencePrevEventId ?? this.recurrencePrevEventId,
      recurrenceNextEventId: clearRecurrenceNav
          ? null
          : recurrenceNextEventId ?? this.recurrenceNextEventId,
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
          startTime == other.startTime &&
          endTime == other.endTime &&
          scheduledAtUtc == other.scheduledAtUtc &&
          listEquals(afterImagePaths, other.afterImagePaths) &&
          listEquals(gear, other.gear) &&
          moderationApproved == other.moderationApproved;

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
        startTime,
        endTime,
        scheduledAtUtc,
        Object.hashAll(afterImagePaths),
        Object.hashAll(gear),
        moderationApproved,
      );

  factory EcoEvent.fromJson(Map<String, dynamic> json) {
    T enumByNameOr<T extends Enum>(List<T> values, String? name, T fallback) {
      if (name == null) return fallback;
      for (final T value in values) {
        if (value.name == name) return value;
      }
      assert(() {
        debugPrint('[EcoEvent] Unknown enum value "$name" for '
            '${fallback.runtimeType}, falling back to ${fallback.name}');
        return true;
      }());
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
      organizerAvatarUrl: json['organizerAvatarUrl'] as String?,
      date: parseDate(json['date'], now),
      startTime: decodeTime(json['startTime'], const EventTime(hour: 10, minute: 0)),
      endTime: decodeTime(json['endTime'], const EventTime(hour: 12, minute: 0)),
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
      afterImagePaths: (json['afterImagePaths'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      gear: (json['gear'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .map((String raw) => enumByNameOr<EventGear>(
                EventGear.values,
                raw,
                EventGear.trashBags,
              ))
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
      moderationApproved: (json['moderationApproved'] as bool?) ?? true,
      siteLat: (json['siteLat'] as num?)?.toDouble(),
      siteLng: (json['siteLng'] as num?)?.toDouble(),
      recurrenceRule: json['recurrenceRule'] as String?,
      parentEventId: json['parentEventId'] as String?,
      recurrenceIndex: (json['recurrenceIndex'] as num?)?.toInt(),
      recurrenceSeriesTotal: (json['recurrenceSeriesTotal'] as num?)?.toInt(),
      recurrenceSeriesPosition:
          (json['recurrenceSeriesPosition'] as num?)?.toInt(),
      recurrencePrevEventId: json['recurrencePrevEventId'] as String?,
      recurrenceNextEventId: json['recurrenceNextEventId'] as String?,
      scheduledAtUtc: () {
        final String? iso = json['scheduledAtUtc'] as String? ??
            json['scheduledAt'] as String?;
        if (iso == null) return null;
        final DateTime? parsed = DateTime.tryParse(iso);
        return parsed?.toUtc();
      }(),
    );
  }

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
      if (organizerAvatarUrl != null) 'organizerAvatarUrl': organizerAvatarUrl,
      'date': date.toIso8601String(),
      'startTime': <String, int>{
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': <String, int>{
        'hour': endTime.hour,
        'minute': endTime.minute,
      },
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
    };
  }
}

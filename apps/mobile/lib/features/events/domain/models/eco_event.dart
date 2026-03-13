import 'package:chisto_mobile/shared/current_user.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Event time – plain domain type replacing Flutter's TimeOfDay
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Event-specific categories (action type, not pollution type)
// ---------------------------------------------------------------------------

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
}

// ---------------------------------------------------------------------------
// Gear items (multi-select)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Cleanup scale (single-select)
// ---------------------------------------------------------------------------

enum CleanupScale {
  small('Small (1–5 people)', 'Quick spot cleanup, one bag or two.'),
  medium('Medium (6–15 people)', 'Half-day effort, several areas covered.'),
  large('Large (16–40 people)', 'Organized group, heavy waste removal.'),
  massive('Massive (40+ people)', 'City-wide or multi-site event.');

  const CleanupScale(this.label, this.description);
  final String label;
  final String description;
}

// ---------------------------------------------------------------------------
// Difficulty level (single-select)
// ---------------------------------------------------------------------------

enum EventDifficulty {
  easy('Easy', 'Flat terrain, light waste, family-friendly.', 0xFF2FD788),
  moderate('Moderate', 'Mixed terrain or bulky items, some effort.', 0xFFF5A623),
  hard('Hard', 'Steep slopes, heavy debris, or hazardous materials.', 0xFFE6513D);

  const EventDifficulty(this.label, this.description, this.colorValue);
  final String label;
  final String description;
  final int colorValue;
}

// ---------------------------------------------------------------------------
// Event status
// ---------------------------------------------------------------------------

enum EcoEventStatus {
  upcoming('Upcoming', 0xFF2FD788),
  inProgress('In progress', 0xFF3BA3F7),
  completed('Completed', 0xFF7A7A7A),
  cancelled('Cancelled', 0xFFE6513D);

  const EcoEventStatus(this.label, this.colorValue);
  final String label;
  final int colorValue;
}

enum AttendeeCheckInStatus {
  notCheckedIn,
  checkedIn,
}

// ---------------------------------------------------------------------------
// EcoEvent model
// ---------------------------------------------------------------------------

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
  });

  final String id;
  final String title;
  final String description;
  final EcoEventCategory category;
  final String siteId;
  final String siteName;
  final String siteImageUrl;
  final double siteDistanceKm;
  final String organizerId;
  final String organizerName;
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

  bool get isOrganizer => organizerId == CurrentUser.id;
  bool get isJoinable =>
      !isOrganizer &&
      status != EcoEventStatus.completed &&
      status != EcoEventStatus.cancelled;
  bool get isLifecycleClosed =>
      status == EcoEventStatus.completed || status == EcoEventStatus.cancelled;
  bool get isCheckedIn => attendeeCheckInStatus == AttendeeCheckInStatus.checkedIn;
  bool get hasAfterImages => afterImagePaths.isNotEmpty;
  bool get canOpenAttendeeCheckIn =>
      isJoined && !isOrganizer && status == EcoEventStatus.inProgress && isCheckInOpen;

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

  String get formattedDate {
    const List<String> months = <String>[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

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
    DateTime? date,
    EventTime? startTime,
    EventTime? endTime,
    int? participantCount,
    int? maxParticipants,
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
    EventDifficulty? difficulty,
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
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
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
      scale: scale ?? this.scale,
      difficulty: difficulty ?? this.difficulty,
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
          listEquals(afterImagePaths, other.afterImagePaths) &&
          listEquals(gear, other.gear);

  @override
  int get hashCode => Object.hash(
        id,
        title,
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
      );

  factory EcoEvent.fromJson(Map<String, dynamic> json) {
    T enumByNameOr<T extends Enum>(List<T> values, String? name, T fallback) {
      if (name == null) return fallback;
      for (final T value in values) {
        if (value.name == name) return value;
      }
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
          : parseDate(json['attendeeCheckedInAt'], now),
      reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
      reminderAt: json['reminderAt'] == null
          ? null
          : parseDate(json['reminderAt'], now),
      afterImagePaths: (json['afterImagePaths'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      gear: (json['gear'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic raw) => enumByNameOr<EventGear>(
                EventGear.values,
                raw as String?,
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
      'organizerId': organizerId,
      'organizerName': organizerName,
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
    };
  }
}

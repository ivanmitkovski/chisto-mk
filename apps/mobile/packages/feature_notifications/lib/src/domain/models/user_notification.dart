import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:feature_notifications/src/domain/models/notification_actor.dart';

enum UserNotificationType {
  siteUpdate,
  reportStatus,
  upvote,
  comment,
  nearbyReport,
  cleanupEvent,
  eventChat,
  system,
  achievement,
  welcome,
}

UserNotificationType parseNotificationType(String? raw) {
  switch (raw) {
    case 'SITE_UPDATE':
      return UserNotificationType.siteUpdate;
    case 'REPORT_STATUS':
      return UserNotificationType.reportStatus;
    case 'UPVOTE':
      return UserNotificationType.upvote;
    case 'COMMENT':
      return UserNotificationType.comment;
    case 'NEARBY_REPORT':
      return UserNotificationType.nearbyReport;
    case 'CLEANUP_EVENT':
      return UserNotificationType.cleanupEvent;
    case 'EVENT_CHAT':
      return UserNotificationType.eventChat;
    case 'SYSTEM':
      return UserNotificationType.system;
    case 'ACHIEVEMENT':
      return UserNotificationType.achievement;
    case 'WELCOME':
      return UserNotificationType.welcome;
    default:
      return UserNotificationType.system;
  }
}

class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
    this.sentAt,
    this.threadKey,
    this.groupKey,
    this.archivedAt,
    this.actor,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: parseNotificationType(json['type'] as String?),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      data: safeAsStringKeyedMap(json['data']),
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : null,
      threadKey: json['threadKey'] as String?,
      groupKey: json['groupKey'] as String?,
      archivedAt: json['archivedAt'] != null
          ? DateTime.parse(json['archivedAt'] as String)
          : null,
      actor: _parseActor(json['actor']),
    );
  }

  static NotificationActor? _parseActor(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      return NotificationActor.fromJson(raw);
    } on Object {
      return null;
    }
  }

  final String id;
  final String title;
  final String body;
  final UserNotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final DateTime? sentAt;
  final String? threadKey;
  final String? groupKey;
  final DateTime? archivedAt;
  final NotificationActor? actor;

  UserNotification copyWith({
    bool? isRead,
    DateTime? archivedAt,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    NotificationActor? actor,
  }) {
    return UserNotification(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      sentAt: sentAt,
      threadKey: threadKey,
      groupKey: groupKey,
      archivedAt: archivedAt ?? this.archivedAt,
      actor: actor ?? this.actor,
    );
  }

  String? get targetSiteId => data?['siteId'] as String?;
  String? get targetReportId => data?['reportId'] as String?;
  String? get targetTab => data?['targetTab'] as String?;
  String? get targetAction => data?['targetAction'] as String?;
  String? get targetEventId => data?['eventId'] as String?;
  String? get dataKind => data?['kind'] as String?;
  String? get eventTitleFromData {
    final String? t = data?['eventTitle'] as String?;
    if (t != null && t.trim().isNotEmpty) return t.trim();
    return data?['threadTitle'] as String?;
  }

  String? get highlightActorUserId => data?['actorUserId'] as String?;
  String? get highlightCommentId => data?['commentId'] as String?;

  int? get messageCount {
    final Object? raw = data?['messageCount'];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}

String toNotificationTypeApiValue(UserNotificationType type) {
  switch (type) {
    case UserNotificationType.siteUpdate:
      return 'SITE_UPDATE';
    case UserNotificationType.reportStatus:
      return 'REPORT_STATUS';
    case UserNotificationType.upvote:
      return 'UPVOTE';
    case UserNotificationType.comment:
      return 'COMMENT';
    case UserNotificationType.nearbyReport:
      return 'NEARBY_REPORT';
    case UserNotificationType.cleanupEvent:
      return 'CLEANUP_EVENT';
    case UserNotificationType.eventChat:
      return 'EVENT_CHAT';
    case UserNotificationType.system:
      return 'SYSTEM';
    case UserNotificationType.achievement:
      return 'ACHIEVEMENT';
    case UserNotificationType.welcome:
      return 'WELCOME';
  }
}

class NotificationPreference {
  const NotificationPreference({
    required this.type,
    required this.muted,
    this.mutedUntil,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      type: parseNotificationType(json['type'] as String?),
      muted: json['muted'] as bool? ?? false,
      mutedUntil: (json['mutedUntil'] as String?) != null
          ? DateTime.tryParse(json['mutedUntil'] as String)
          : null,
    );
  }

  final UserNotificationType type;
  final bool muted;
  final DateTime? mutedUntil;

  NotificationPreference copyWith({bool? muted, DateTime? mutedUntil}) {
    return NotificationPreference(
      type: type,
      muted: muted ?? this.muted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
    );
  }
}

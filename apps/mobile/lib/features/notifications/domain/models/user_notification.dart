enum UserNotificationType {
  siteUpdate,
  reportStatus,
  upvote,
  comment,
  nearbyReport,
  cleanupEvent,
  system,
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
    case 'SYSTEM':
      return UserNotificationType.system;
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
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: parseNotificationType(json['type'] as String?),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      data: json['data'] as Map<String, dynamic>?,
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : null,
      threadKey: json['threadKey'] as String?,
      groupKey: json['groupKey'] as String?,
    );
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

  UserNotification copyWith({bool? isRead}) {
    return UserNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
      sentAt: sentAt,
      threadKey: threadKey,
      groupKey: groupKey,
    );
  }

  String? get targetSiteId => data?['siteId'] as String?;
  String? get targetTab => data?['targetTab'] as String?;
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
    case UserNotificationType.system:
      return 'SYSTEM';
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

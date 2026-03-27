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
    );
  }

  String? get targetSiteId => data?['siteId'] as String?;
  String? get targetTab => data?['targetTab'] as String?;
}

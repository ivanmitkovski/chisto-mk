class CheckInQrPayload {
  const CheckInQrPayload({
    required this.eventId,
    required this.sessionId,
    required this.nonce,
    required this.issuedAtMs,
  });

  static const String scheme = 'chisto';
  static const String context = 'evt';
  static const String version = 'v1';

  final String eventId;
  final String sessionId;
  final String nonce;
  final int issuedAtMs;

  bool isExpired(Duration ttl) =>
      DateTime.now().millisecondsSinceEpoch - issuedAtMs > ttl.inMilliseconds;

  String encode() {
    return '$scheme:$context:$version:$eventId:$sessionId:$nonce:$issuedAtMs';
  }

  static CheckInQrPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final List<String> parts = raw.split(':');
    if (parts.length != 7) {
      return null;
    }
    if (parts[0] != scheme || parts[1] != context || parts[2] != version) {
      return null;
    }
    final int? issuedAtMs = int.tryParse(parts[6]);
    if (issuedAtMs == null) {
      return null;
    }
    if (parts[3].isEmpty || parts[4].isEmpty || parts[5].isEmpty) {
      return null;
    }
    return CheckInQrPayload(
      eventId: parts[3],
      sessionId: parts[4],
      nonce: parts[5],
      issuedAtMs: issuedAtMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInQrPayload &&
          eventId == other.eventId &&
          sessionId == other.sessionId &&
          nonce == other.nonce &&
          issuedAtMs == other.issuedAtMs;

  @override
  int get hashCode => Object.hash(eventId, sessionId, nonce, issuedAtMs);
}

enum CheckInSubmissionStatus {
  success,
  invalidFormat,
  wrongEvent,
  sessionClosed,
  sessionExpired,
  replayDetected,
  alreadyCheckedIn,
}

class CheckInSubmissionResult {
  const CheckInSubmissionResult({
    required this.status,
    this.checkedInAt,
  });

  final CheckInSubmissionStatus status;
  final DateTime? checkedInAt;

  bool get isSuccess => status == CheckInSubmissionStatus.success;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInSubmissionResult &&
          status == other.status &&
          checkedInAt == other.checkedInAt;

  @override
  int get hashCode => Object.hash(status, checkedInAt);
}

class CheckedInAttendee {
  const CheckedInAttendee({
    required this.id,
    required this.name,
    required this.checkedInAt,
  });

  final String id;
  final String name;
  final DateTime checkedInAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'checkedInAt': checkedInAt.millisecondsSinceEpoch,
      };

  static CheckedInAttendee? fromJson(Map<String, dynamic> json) {
    final String? id = json['id'] as String?;
    final String? name = json['name'] as String?;
    final int? checkedInAtMs = json['checkedInAt'] as int?;
    if (id == null || id.isEmpty || name == null || name.isEmpty || checkedInAtMs == null) {
      return null;
    }
    return CheckedInAttendee(
      id: id,
      name: name,
      checkedInAt: DateTime.fromMillisecondsSinceEpoch(checkedInAtMs),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckedInAttendee && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

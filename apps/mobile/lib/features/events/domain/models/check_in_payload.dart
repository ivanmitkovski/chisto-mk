import 'dart:convert';

class CheckInQrPayload {
  const CheckInQrPayload({
    required this.eventId,
    required this.sessionId,
    required this.nonce,
    required this.issuedAtMs,
    this.opaqueEncoded,
    this.expiresAtMs,
  });

  static const String scheme = 'chisto';
  static const String context = 'evt';
  static const String version = 'v1';
  static const String version2 = 'v2';

  final String eventId;
  final String sessionId;
  final String nonce;
  final int issuedAtMs;

  /// When set, [encode] returns this (server-signed v2 token).
  final String? opaqueEncoded;

  /// Wall-clock expiry from the API (`expiresAt`); drives refresh countdown when set.
  final int? expiresAtMs;

  bool isExpired(Duration ttl) =>
      DateTime.now().millisecondsSinceEpoch - issuedAtMs > ttl.inMilliseconds;

  String encode() =>
      opaqueEncoded ??
      '$scheme:$context:$version:$eventId:$sessionId:$nonce:$issuedAtMs';

  /// Parses GET `/events/:id/check-in/qr` JSON. Returns null if required fields are missing or invalid.
  static CheckInQrPayload? fromOrganizerQrApiJson(Map<String, dynamic> json) {
    final String? qr = json['qrPayload'] as String?;
    final String? sessionId = json['sessionId'] as String?;
    final Object? issuedAtMsRaw = json['issuedAtMs'];
    if (qr == null ||
        qr.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty ||
        issuedAtMsRaw is! num) {
      return null;
    }
    final CheckInQrPayload? parsed = CheckInQrPayload.tryParse(qr);
    if (parsed == null) {
      return null;
    }
    final String? expiresAtIso = json['expiresAt'] as String?;
    final int? expiresAtMs = expiresAtIso == null || expiresAtIso.isEmpty
        ? null
        : DateTime.tryParse(expiresAtIso)?.toLocal().millisecondsSinceEpoch;
    return CheckInQrPayload(
      eventId: parsed.eventId,
      sessionId: sessionId,
      nonce: parsed.nonce,
      issuedAtMs: issuedAtMsRaw.round(),
      opaqueEncoded: qr,
      expiresAtMs: expiresAtMs,
    );
  }

  static String _paddedBase64Url(String input) {
    final int mod = input.length % 4;
    if (mod == 0) {
      return input;
    }
    return input.padRight(input.length + (4 - mod), '=');
  }

  static CheckInQrPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    const String v2Prefix = '$scheme:$context:$version2:';
    if (raw.startsWith(v2Prefix)) {
      final String rest = raw.substring(v2Prefix.length);
      final int dot = rest.lastIndexOf('.');
      if (dot <= 0 || dot >= rest.length - 1) {
        return null;
      }
      final String bodyB64 = rest.substring(0, dot);
      try {
        final List<int> jsonBytes =
            base64Url.decode(_paddedBase64Url(bodyB64));
        final Object? decoded = json.decode(utf8.decode(jsonBytes));
        if (decoded is! Map<String, dynamic>) {
          return null;
        }
        final Map<String, dynamic> map = decoded;
        final String? e = map['e'] as String?;
        final String? s = map['s'] as String?;
        final String? j = map['j'] as String?;
        final Object? iat = map['iat'];
        if (e == null ||
            e.isEmpty ||
            s == null ||
            s.isEmpty ||
            j == null ||
            j.isEmpty ||
            iat is! num) {
          return null;
        }
        return CheckInQrPayload(
          eventId: e,
          sessionId: s,
          nonce: j,
          issuedAtMs: (iat * 1000).round(),
          opaqueEncoded: raw,
        );
      } on Object {
        return null;
      }
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
          issuedAtMs == other.issuedAtMs &&
          opaqueEncoded == other.opaqueEncoded &&
          expiresAtMs == other.expiresAtMs;

  @override
  int get hashCode =>
      Object.hash(
        eventId,
        sessionId,
        nonce,
        issuedAtMs,
        opaqueEncoded,
        expiresAtMs,
      );
}

enum CheckInSubmissionStatus {
  success,
  invalidFormat,
  invalidQr,
  wrongEvent,
  sessionClosed,
  sessionExpired,
  replayDetected,
  alreadyCheckedIn,
  requiresJoin,
  checkInUnavailable,
  rateLimited,
  /// No network connection — payload has been queued for offline sync.
  queuedOffline,
}

class CheckInSubmissionResult {
  const CheckInSubmissionResult({
    required this.status,
    this.checkedInAt,
    this.pointsAwarded = 0,
  });

  final CheckInSubmissionStatus status;
  final DateTime? checkedInAt;

  /// Gamification: server points for this check-in (0 if none or offline queue).
  final int pointsAwarded;

  bool get isSuccess => status == CheckInSubmissionStatus.success;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInSubmissionResult &&
          status == other.status &&
          checkedInAt == other.checkedInAt &&
          pointsAwarded == other.pointsAwarded;

  @override
  int get hashCode => Object.hash(status, checkedInAt, pointsAwarded);
}

/// Result of organizer manual check-in for a joined volunteer.
class ManualCheckInResult {
  const ManualCheckInResult({
    required this.recorded,
    this.pointsAwarded = 0,
  });

  final bool recorded;

  /// Points credited to the volunteer’s account (server).
  final int pointsAwarded;
}

class CheckedInAttendee {
  const CheckedInAttendee({
    required this.id,
    required this.name,
    required this.checkedInAt,
    this.userId,
  });

  final String id;
  final String name;
  final DateTime checkedInAt;

  /// Present when check-in is tied to an app user (`u:<userId>`); null for legacy guest rows.
  final String? userId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'checkedInAt': checkedInAt.millisecondsSinceEpoch,
        if (userId != null) 'userId': userId,
      };

  static CheckedInAttendee? fromJson(Map<String, dynamic> json) {
    final String? id = json['id'] as String?;
    final String? name = json['name'] as String?;
    final int? checkedInAtMs = json['checkedInAt'] as int?;
    if (id == null || id.isEmpty || name == null || name.isEmpty || checkedInAtMs == null) {
      return null;
    }
    final String? uid = json['userId'] as String?;
    return CheckedInAttendee(
      id: id,
      name: name,
      checkedInAt: DateTime.fromMillisecondsSinceEpoch(checkedInAtMs),
      userId: uid != null && uid.isNotEmpty ? uid : null,
    );
  }

  static CheckedInAttendee? fromApiJson(Map<String, dynamic> json) {
    final String? id = json['id'] as String?;
    final String? name = json['name'] as String?;
    final String? checkedInAtIso = json['checkedInAt'] as String?;
    if (id == null ||
        id.isEmpty ||
        name == null ||
        name.isEmpty ||
        checkedInAtIso == null ||
        checkedInAtIso.isEmpty) {
      return null;
    }
    final DateTime? at = DateTime.tryParse(checkedInAtIso);
    if (at == null) {
      return null;
    }
    final String? uid = json['userId'] as String?;
    return CheckedInAttendee(
      id: id,
      name: name,
      checkedInAt: at.toLocal(),
      userId: uid != null && uid.isNotEmpty ? uid : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckedInAttendee && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

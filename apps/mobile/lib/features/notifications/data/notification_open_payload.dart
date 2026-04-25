/// UUID v4-style id check for push/deeplink routing (rejects obvious garbage).
bool notificationOpenPayloadLooksLikeUuid(String raw) {
  final String t = raw.trim();
  final RegExp uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  return uuid.hasMatch(t);
}

/// API cleanup/event ids are Prisma `cuid()` (25 chars) or legacy UUID-shaped strings.
bool notificationOpenPayloadLooksLikeEventId(String raw) {
  final String t = raw.trim();
  if (t.isEmpty || t.length > 80) {
    return false;
  }
  if (notificationOpenPayloadLooksLikeUuid(t)) {
    return true;
  }
  return RegExp(r'^c[a-z0-9]{24}$').hasMatch(t);
}

/// Chat app bar title: server `threadTitle`, then FCM notification title, then cached list title.
String notificationOpenResolveChatBarTitle({
  required Map<String, dynamic> data,
  String? notificationTitle,
  String? cachedEventTitle,
}) {
  final String fromData = (data['threadTitle'] as String?)?.trim() ?? '';
  if (fromData.isNotEmpty) {
    return fromData;
  }
  final String fromNotif = notificationTitle?.trim() ?? '';
  if (fromNotif.isNotEmpty) {
    return fromNotif;
  }
  return (cachedEventTitle ?? '').trim();
}

import 'dart:convert';

import 'package:chisto_mobile/core/serialization/safe_json.dart';

int? getAccessTokenExpiry(String accessToken) {
  final List<String> parts = accessToken.split('.');
  if (parts.length != 3) return null;
  try {
    final String normalized = base64Url.normalize(parts[1]);
    final String payloadJson = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic>? payload = safeJsonDecodeMap(payloadJson);
    if (payload == null) return null;
    final Object? exp = payload['exp'];
    if (exp is int) return exp;
    return null;
  } catch (_) {
    return null;
  }
}

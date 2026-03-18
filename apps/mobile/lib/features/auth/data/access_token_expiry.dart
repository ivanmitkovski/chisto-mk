import 'dart:convert';

int? getAccessTokenExpiry(String accessToken) {
  final List<String> parts = accessToken.split('.');
  if (parts.length != 3) return null;
  try {
    final String normalized = base64Url.normalize(parts[1]);
    final String payloadJson = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    final Object? exp = payload['exp'];
    if (exp is int) return exp;
    return null;
  } catch (_) {
    return null;
  }
}

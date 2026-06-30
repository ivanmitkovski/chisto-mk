import 'dart:convert';

import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:chisto_infrastructure/core/time/server_clock.dart';

int? _jwtClaimInt(String accessToken, String claim) {
  final List<String> parts = accessToken.split('.');
  if (parts.length != 3) return null;
  try {
    final String normalized = base64Url.normalize(parts[1]);
    final String payloadJson = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic>? payload = safeJsonDecodeMap(payloadJson);
    if (payload == null) return null;
    final Object? value = payload[claim];
    if (value is int) return value;
    return null;
  } catch (_) {
    return null;
  }
}

int? getAccessTokenExpiry(String accessToken) =>
    _jwtClaimInt(accessToken, 'exp');

int? getAccessTokenIssuedAt(String accessToken) =>
    _jwtClaimInt(accessToken, 'iat');

/// True when the access JWT is expired or within [nearExpiryFraction] of expiry.
///
/// Uses [ServerClock] so device clock skew does not skip a needed refresh.
bool accessTokenNeedsRefreshSoon(
  String accessToken, {
  double nearExpiryFraction = 0.2,
}) {
  final int? exp = getAccessTokenExpiry(accessToken);
  if (exp == null) return false;
  final double nowSec =
      ServerClock.instance.nowUtc().millisecondsSinceEpoch / 1000.0;
  final double remainingSec = exp - nowSec;
  if (remainingSec <= 0) return true;

  final int? iat = getAccessTokenIssuedAt(accessToken);
  if (iat != null) {
    final double lifetimeSec = (exp - iat).toDouble();
    if (lifetimeSec > 0) {
      return remainingSec <= lifetimeSec * nearExpiryFraction;
    }
  }

  // Fallback when `iat` is missing: ~20% of a 15-minute access TTL.
  return remainingSec <= 180;
}

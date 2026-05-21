import 'dart:convert';

/// Defensive JSON helpers for API/cache payloads (Wave 11).
Map<String, dynamic>? safeAsStringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );
  }
  return null;
}

List<dynamic>? safeAsList(Object? value) {
  if (value is List<dynamic>) {
    return value;
  }
  if (value is List) {
    return List<dynamic>.from(value);
  }
  return null;
}

Map<String, dynamic>? safeJsonDecodeMap(String raw) {
  try {
    final Object? decoded = jsonDecode(raw);
    return safeAsStringKeyedMap(decoded);
  } on Object {
    return null;
  }
}

List<dynamic>? safeJsonDecodeList(String raw) {
  try {
    final Object? decoded = jsonDecode(raw);
    return safeAsList(decoded);
  } on Object {
    return null;
  }
}

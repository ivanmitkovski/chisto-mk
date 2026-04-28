import 'package:chisto_mobile/features/home/domain/models/co_reporter_profile.dart';

bool sitesApiJsonTruthy(Object? value) {
  if (value == true) return true;
  if (value == false || value == null) return false;
  if (value is num) return value != 0;
  if (value is String) {
    final String t = value.trim().toLowerCase();
    return t == 'true' || t == '1' || t == 'yes';
  }
  return false;
}

bool sitesApiJsonBoolField(
  Map<String, dynamic> json,
  String camel,
  String snake,
) {
  return sitesApiJsonTruthy(json[camel]) || sitesApiJsonTruthy(json[snake]);
}

/// Matches [SiteReport.reporterName] when the API omits a display name.
const String kSitesApiAnonymousCoReporterName = 'Anonymous';

String sitesApiCoReporterDisplayName(Map<String, dynamic>? user) {
  if (user == null) {
    return kSitesApiAnonymousCoReporterName;
  }
  final String fn =
      '${user['firstName'] ?? user['first_name'] ?? ''}'.trim();
  final String ln =
      '${user['lastName'] ?? user['last_name'] ?? ''}'.trim();
  final String name = '$fn $ln'.trim();
  return name.isEmpty ? kSitesApiAnonymousCoReporterName : name;
}

String sitesApiPreferRicherCoReporterName(String existing, String incoming) {
  if (existing == kSitesApiAnonymousCoReporterName &&
      incoming != kSitesApiAnonymousCoReporterName) {
    return incoming;
  }
  if (incoming == kSitesApiAnonymousCoReporterName &&
      existing != kSitesApiAnonymousCoReporterName) {
    return existing;
  }
  return existing;
}

String? sitesApiPreferNonEmptyString(String? a, String? b) {
  final String? x = a?.trim();
  final String? y = b?.trim();
  if (x != null && x.isNotEmpty) {
    return x;
  }
  if (y != null && y.isNotEmpty) {
    return y;
  }
  return null;
}

/// Some gateways or older clients wrap entities as `{ "data": <site> }`.
Map<String, dynamic> sitesApiSiteEntityJsonRoot(Map<String, dynamic> json) {
  final Object? directReports = json['reports'];
  if (directReports is List<dynamic>) {
    return json;
  }
  final Object? data = json['data'];
  if (data is Map<String, dynamic>) {
    final Object? dr = data['reports'];
    if (dr is List<dynamic>) {
      return data;
    }
    final Object? site = data['site'];
    if (site is Map<String, dynamic>) {
      final Object? sr = site['reports'];
      if (sr is List<dynamic>) {
        return site;
      }
    }
    if (data['id'] is String &&
        (data.containsKey('latitude') ||
            data.containsKey('longitude') ||
            data.containsKey('upvotesCount'))) {
      return data;
    }
  }
  return json;
}

Map<String, dynamic>? sitesApiJsonObjectToStringKeyedMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final MapEntry<dynamic, dynamic> e in raw.entries) {
      out[e.key.toString()] = e.value;
    }
    return out;
  }
  return null;
}

List<Map<String, dynamic>> sitesApiMapListOfObjects(List<dynamic> raw) {
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final dynamic item in raw) {
    final Map<String, dynamic>? m = sitesApiJsonObjectToStringKeyedMap(item);
    if (m != null) {
      out.add(m);
    }
  }
  return out;
}

List<dynamic> sitesApiReportCoReportersList(Map<String, dynamic> r) {
  final Object? v = r['coReporters'] ?? r['co_reporters'];
  if (v is List<dynamic>) {
    return v;
  }
  return <dynamic>[];
}

List<dynamic> sitesApiReportMediaUrlsList(Map<String, dynamic> r) {
  final Object? v = r['mediaUrls'] ?? r['media_urls'];
  if (v is List<dynamic>) {
    return v;
  }
  return <dynamic>[];
}

String? sitesApiCoReporterRowUserId(Map<String, dynamic> co) {
  final Object? v = co['userId'] ?? co['user_id'];
  if (v is String) {
    final String t = v.trim();
    return t.isEmpty ? null : t;
  }
  if (v is num) {
    return v.toString();
  }
  return null;
}

Map<String, dynamic>? sitesApiCoReporterRowUser(Map<String, dynamic> co) {
  final Object? u = co['user'] ?? co['User'];
  return sitesApiJsonObjectToStringKeyedMap(u);
}

DateTime? sitesApiCoReporterRowReportedAt(Map<String, dynamic> co) {
  final Object? raw = co['reportedAt'] ?? co['reported_at'];
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}

List<String> sitesApiSiteDetailCoReporterNamesFromApiField(Object? raw) {
  if (raw is! List<dynamic>) {
    return <String>[];
  }
  final List<String> out = <String>[];
  for (final dynamic e in raw) {
    if (e is String) {
      final String t = e.trim();
      if (t.isNotEmpty) {
        out.add(t);
      }
    } else if (e != null) {
      final String t = e.toString().trim();
      if (t.isNotEmpty) {
        out.add(t);
      }
    }
  }
  return out;
}

List<CoReporterProfile> sitesApiCoReporterSummariesFromApiField(Object? raw) {
  if (raw is! List<dynamic>) {
    return <CoReporterProfile>[];
  }
  final List<CoReporterProfile> out = <CoReporterProfile>[];
  for (final dynamic item in raw) {
    final Map<String, dynamic>? m = sitesApiJsonObjectToStringKeyedMap(item);
    if (m == null) continue;
    final String name = '${m['name'] ?? m['displayName'] ?? ''}'.trim();
    if (name.isEmpty) continue;
    final Object? av = m['avatarUrl'] ?? m['avatar_url'];
    final String? avatarUrl =
        av is String && av.trim().isNotEmpty ? av.trim() : null;
    final String? userId = sitesApiCoReporterRowUserId(m);
    out.add(
      CoReporterProfile(
        displayName: name,
        avatarUrl: avatarUrl,
        userId: userId,
      ),
    );
  }
  return out;
}

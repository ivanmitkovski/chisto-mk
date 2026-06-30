import 'package:feature_home/src/domain/models/co_reporter_profile.dart';

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

/// Matches API `Anonymous` fallback for redacted reporter identity.
const String kSitesApiAnonymousCoReporterName = 'Anonymous';

/// True when API (or legacy payloads) redacted a name to a single initial, e.g. `K.`.
bool sitesApiIsAbbreviatedReporterLabel(String label) {
  return RegExp(r'^[A-Za-zА-Яа-яЀ-ӿ]\.$').hasMatch(label);
}

/// Public reporter label from site detail / report JSON (full name preferred).
String sitesApiPublicReporterDisplayName(Map<String, dynamic>? reporter) {
  if (reporter == null) {
    return kSitesApiAnonymousCoReporterName;
  }
  if (sitesApiReporterIsDeleted(reporter)) {
    return '';
  }
  final String fn = '${reporter['firstName'] ?? reporter['first_name'] ?? ''}'
      .trim();
  final String ln = '${reporter['lastName'] ?? reporter['last_name'] ?? ''}'
      .trim();
  final String fullName = '$fn $ln'.trim();
  if (fullName.isNotEmpty) {
    return fullName;
  }
  final String displayLabel =
      '${reporter['displayLabel'] ?? reporter['display_label'] ?? ''}'.trim();
  if (displayLabel.isNotEmpty &&
      !sitesApiIsAbbreviatedReporterLabel(displayLabel)) {
    return displayLabel;
  }
  if (displayLabel.isNotEmpty) {
    return displayLabel;
  }
  return kSitesApiAnonymousCoReporterName;
}

bool sitesApiReporterIsDeleted(Map<String, dynamic>? reporter) {
  if (reporter == null) {
    return false;
  }
  if (reporter['isDeleted'] == true) {
    return true;
  }
  final String status = '${reporter['status'] ?? ''}'.trim().toUpperCase();
  return status == 'DELETED';
}

String sitesApiCoReporterDisplayName(Map<String, dynamic>? user) {
  return sitesApiPublicReporterDisplayName(user);
}

/// Co-reporter row may expose `displayLabel` on the row or nested `user`.
String sitesApiCoReporterRowDisplayName(Map<String, dynamic>? co) {
  if (co == null) {
    return kSitesApiAnonymousCoReporterName;
  }
  if (sitesApiCoReporterRowIsDeleted(co)) {
    return '';
  }
  final Map<String, dynamic>? user = sitesApiCoReporterRowUser(co);
  final String fromUser = sitesApiPublicReporterDisplayName(user);
  if (fromUser != kSitesApiAnonymousCoReporterName) {
    return fromUser;
  }
  final String rowLabel = '${co['displayLabel'] ?? co['display_label'] ?? ''}'
      .trim();
  if (rowLabel.isNotEmpty && !sitesApiIsAbbreviatedReporterLabel(rowLabel)) {
    return rowLabel;
  }
  if (rowLabel.isNotEmpty) {
    return rowLabel;
  }
  return kSitesApiAnonymousCoReporterName;
}

bool sitesApiCoReporterRowIsDeleted(Map<String, dynamic>? co) {
  if (co == null) {
    return false;
  }
  if (co['isDeleted'] == true) {
    return true;
  }
  final Map<String, dynamic>? user = sitesApiCoReporterRowUser(co);
  return sitesApiReporterIsDeleted(user);
}

List<String> sitesApiStringListFromJsonField(Object? raw) {
  if (raw is! List<dynamic>) {
    return <String>[];
  }
  final List<String> out = <String>[];
  for (final dynamic item in raw) {
    if (item is String) {
      final String t = item.trim();
      if (t.isNotEmpty) {
        out.add(t);
      }
    }
  }
  return out;
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

DateTime? sitesApiReportCreatedAt(Map<String, dynamic> report) {
  final Object? raw = report['createdAt'] ?? report['created_at'];
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}

/// Chronologically first report on a site (minimum `createdAt`).
Map<String, dynamic> sitesApiEarliestReport(
  List<Map<String, dynamic>> reports,
) {
  assert(reports.isNotEmpty, 'reports must not be empty');
  Map<String, dynamic> earliest = reports.first;
  DateTime earliestAt = sitesApiReportCreatedAt(earliest) ?? DateTime.now();
  for (int i = 1; i < reports.length; i++) {
    final Map<String, dynamic> candidate = reports[i];
    final DateTime candidateAt =
        sitesApiReportCreatedAt(candidate) ?? DateTime.now();
    if (candidateAt.isBefore(earliestAt)) {
      earliest = candidate;
      earliestAt = candidateAt;
    }
  }
  return earliest;
}

/// Most recent report on a site (maximum `createdAt`).
Map<String, dynamic> sitesApiLatestReport(List<Map<String, dynamic>> reports) {
  assert(reports.isNotEmpty, 'reports must not be empty');
  Map<String, dynamic> latest = reports.first;
  DateTime latestAt = sitesApiReportCreatedAt(latest) ?? DateTime(0);
  for (int i = 1; i < reports.length; i++) {
    final Map<String, dynamic> candidate = reports[i];
    final DateTime candidateAt =
        sitesApiReportCreatedAt(candidate) ?? DateTime(0);
    if (candidateAt.isAfter(latestAt)) {
      latest = candidate;
      latestAt = candidateAt;
    }
  }
  return latest;
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
    final bool isDeleted = m['isDeleted'] as bool? ?? false;
    final String name = '${m['name'] ?? m['displayName'] ?? ''}'.trim();
    if (name.isEmpty && !isDeleted) continue;
    final Object? av = m['avatarUrl'] ?? m['avatar_url'];
    final String? avatarUrl = av is String && av.trim().isNotEmpty
        ? av.trim()
        : null;
    final String? userId = sitesApiCoReporterRowUserId(m);
    out.add(
      CoReporterProfile(
        displayName: name,
        isDeleted: isDeleted,
        avatarUrl: avatarUrl,
        userId: userId,
      ),
    );
  }
  return out;
}

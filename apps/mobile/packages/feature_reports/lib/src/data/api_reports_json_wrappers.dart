/// POST /reports may be wrapped as `{ data: { reportId, ... } }` by gateways.
Map<String, dynamic> createReportSubmitPayload(Map<String, dynamic> json) {
  final Object? data = json['data'];
  if (data is Map<String, dynamic> && data['reportId'] != null) {
    return data;
  }
  return json;
}

/// Some gateways return `{ data: { ...entity } }` for single-resource GETs.
Map<String, dynamic> singleResourceReportPayload(Map<String, dynamic> json) {
  final Object? data = json['data'];
  if (data is Map<String, dynamic> &&
      (data.containsKey('id') ||
          data.containsKey('mediaUrls') ||
          data.containsKey('title'))) {
    return data;
  }
  return json;
}

String normalizeReportMediaFetchUrl(String raw) {
  final String s = raw.trim();
  if (s.isEmpty) return s;
  if (s.startsWith('//')) {
    return 'https:$s';
  }
  return s;
}

List<String> reportMediaUrlsFromJson(Map<String, dynamic> json) {
  final Object? raw = json['mediaUrls'] ?? json['media_urls'];
  if (raw == null) {
    return <String>[];
  }
  final List<dynamic> mediaList = raw is List<dynamic> ? raw : <dynamic>[raw];
  final List<String> out = <String>[];
  for (final dynamic e in mediaList) {
    if (e is String) {
      final String n = normalizeReportMediaFetchUrl(e);
      if (n.isNotEmpty) {
        out.add(n);
      }
    } else if (e is Map<String, dynamic>) {
      final Object? u = e['url'] ?? e['href'];
      if (u is String) {
        final String n = normalizeReportMediaFetchUrl(u);
        if (n.isNotEmpty) {
          out.add(n);
        }
      }
    }
  }
  return out;
}

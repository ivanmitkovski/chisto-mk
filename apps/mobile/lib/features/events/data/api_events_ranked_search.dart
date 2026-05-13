import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';

/// JSON body for `POST /events/search` (ranked full-text + optional geo / filters).
Map<String, dynamic> buildRankedEventsSearchBody({
  required EcoEventSearchParams params,
  required double? nearLat,
  required double? nearLng,
}) {
  final String q = params.query!.trim();
  final Map<String, dynamic> body = <String, dynamic>{
    'query': q,
    'limit': 30,
  };
  if (nearLat != null && nearLng != null) {
    body['nearLat'] = nearLat;
    body['nearLng'] = nearLng;
  }
  if (params.categories.isNotEmpty) {
    final List<String> keys = params.categories.map((EcoEventCategory c) => c.key).toList()..sort();
    body['category'] = keys.join(',');
  }
  if (params.statuses.isNotEmpty) {
    final List<String> keys = params.statuses.map((EcoEventStatus s) => s.apiKey).toList()..sort();
    body['status'] = keys.join(',');
  }
  if (params.dateFrom != null) {
    body['dateFrom'] =
        '${params.dateFrom!.year.toString().padLeft(4, '0')}-'
        '${params.dateFrom!.month.toString().padLeft(2, '0')}-'
        '${params.dateFrom!.day.toString().padLeft(2, '0')}';
  }
  if (params.dateTo != null) {
    body['dateTo'] =
        '${params.dateTo!.year.toString().padLeft(4, '0')}-'
        '${params.dateTo!.month.toString().padLeft(2, '0')}-'
        '${params.dateTo!.day.toString().padLeft(2, '0')}';
  }
  return body;
}

/// Parses `suggestions` from a ranked search JSON envelope.
List<String> parseRankedSearchSuggestions(Map<String, dynamic>? json) {
  if (json == null) {
    return const <String>[];
  }
  final Object? raw = json['suggestions'];
  if (raw is! List<dynamic>) {
    return const <String>[];
  }
  return raw.whereType<String>().toList(growable: false);
}

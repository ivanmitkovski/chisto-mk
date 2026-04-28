import 'package:shared_preferences/shared_preferences.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/home/domain/models/site_report_reason.dart';

const String _kReportedSiteIdsKey = 'chisto_site_issue_reported_ids';

class SiteIssueReportRepository {
  SiteIssueReportRepository({SharedPreferences? prefs})
      : _prefs = prefs;

  final SharedPreferences? _prefs;

  Future<Set<String>> _loadReportedIds() async {
    final SharedPreferences prefs = _prefs ?? await SharedPreferences.getInstance();
    final List<dynamic>? raw = prefs.getStringList(_kReportedSiteIdsKey);
    if (raw == null) return <String>{};
    return raw.map((Object? e) => e.toString()).toSet();
  }

  Future<void> _saveReportedIds(Set<String> ids) async {
    final SharedPreferences prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setStringList(_kReportedSiteIdsKey, ids.toList());
  }

  Future<bool> hasReported(String siteId) async {
    final Set<String> ids = await _loadReportedIds();
    return ids.contains(siteId);
  }

  Future<void> submitReport({
    required String siteId,
    required SiteReportReason reason,
    String? details,
  }) async {
    await ServiceLocator.instance.sitesRepository.submitFeedFeedback(
      siteId,
      feedbackType: 'misleading',
      metadata: <String, dynamic>{
        'source': 'report_issue',
        'reason': reason.name,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
    final Set<String> ids = await _loadReportedIds();
    ids.add(siteId);
    await _saveReportedIds(ids);
  }
}

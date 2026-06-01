import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_home/src/domain/models/site_report_reason.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kReportedSiteIdsKey = 'chisto_site_issue_reported_ids';

class SiteIssueReportRepository {
  SiteIssueReportRepository({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;

  Future<Set<String>> _loadReportedIds() async {
    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
    final List<dynamic>? raw = prefs.getStringList(_kReportedSiteIdsKey);
    if (raw == null) return <String>{};
    return raw.map((Object? e) => e.toString()).toSet();
  }

  Future<void> _saveReportedIds(Set<String> ids) async {
    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
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
    await readRoot(sitesRepositoryProvider).submitFeedFeedback(
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

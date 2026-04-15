import 'dart:convert';

import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists an in-progress report draft locally (photo paths + text fields only).
class ReportDraftLocalStore {
  ReportDraftLocalStore._();

  static const String _prefsKey = 'chisto_report_draft_v1';

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  static Future<void> saveDraft({
    required ReportDraft draft,
    required String title,
    required String description,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> map = <String, dynamic>{
      'title': title,
      'description': description,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'address': draft.address,
      'severity': draft.severity,
      'category': draft.category?.apiString,
      'cleanupEffort': draft.cleanupEffort?.apiKey,
      'photos': draft.photos.map((XFile f) => f.path).toList(),
    };
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  static Future<ReportDraft?> loadDraft() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final Map<String, dynamic> m = decoded;
    final List<dynamic>? paths = m['photos'] as List<dynamic>?;
    final List<XFile> photos = <XFile>[];
    if (paths != null) {
      for (final Object? p in paths) {
        if (p is String && p.isNotEmpty) {
          photos.add(XFile(p));
        }
      }
    }
    final String? catStr = m['category'] as String?;
    return ReportDraft(
      photos: photos,
      category: ReportCategory.fromApiString(catStr),
      title: (m['title'] as String?) ?? '',
      description: (m['description'] as String?) ?? '',
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      address: m['address'] as String?,
      cleanupEffort: CleanupEffort.fromApiString(m['cleanupEffort'] as String?),
      severity: (m['severity'] as num?)?.toInt() ?? 3,
    );
  }
}

import 'dart:convert';

import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:image_picker/image_picker.dart';

/// JSON serialization for [ReportDraft] + title/description (matches legacy SP shape).
///
/// [draftCodecVersion] 2: photo paths are relative to app documents (managed store).
/// Older rows omit the key; paths may be absolute (picker/camera temp paths).
class ReportDraftJsonCodec {
  ReportDraftJsonCodec._();

  static const int kCodecVersion = 2;

  static Map<String, dynamic> encode({
    required ReportDraft draft,
    required String title,
    required String description,
  }) {
    return <String, dynamic>{
      'draftCodecVersion': kCodecVersion,
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
  }

  static ({ReportDraft draft, String title, String description}) decode(String json) {
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      return (
        draft: ReportDraft(),
        title: '',
        description: '',
      );
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
    return (
      draft: ReportDraft(
        photos: photos,
        category: ReportCategory.fromApiString(catStr),
        title: (m['title'] as String?) ?? '',
        description: (m['description'] as String?) ?? '',
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        address: m['address'] as String?,
        cleanupEffort: CleanupEffort.fromApiString(m['cleanupEffort'] as String?),
        severity: (m['severity'] as num?)?.toInt() ?? 3,
      ),
      title: (m['title'] as String?) ?? '',
      description: (m['description'] as String?) ?? '',
    );
  }
}

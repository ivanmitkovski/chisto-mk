import 'dart:convert';
import 'dart:io';

import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _key = 'chisto_report_draft';

/// Saves draft and stage index for resume. Call when leaving the screen without submit.
Future<void> saveReportDraft({
  required ReportDraft draft,
  required int stageIndex,
}) async {
  final bool hasContent = draft.photos.isNotEmpty ||
      draft.category != null ||
      draft.description.trim().isNotEmpty ||
      (draft.latitude != null && draft.longitude != null);
  if (!hasContent) {
    await clearReportDraft();
    return;
  }

  final List<String> photoPaths = draft.photos
      .map((XFile f) => f.path)
      .where((String p) => p.isNotEmpty)
      .toList();

  final Map<String, dynamic> map = <String, dynamic>{
    'stageIndex': stageIndex.clamp(0, 3),
    'categoryIndex': draft.category != null
        ? ReportCategory.values.indexOf(draft.category!)
        : null,
    'description': draft.description,
    'latitude': draft.latitude,
    'longitude': draft.longitude,
    'address': draft.address,
    'photoPaths': photoPaths,
  };

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(_key, jsonEncode(map));
}

/// Loads saved draft and stage index, or null if none or invalid.
Future<({ReportDraft draft, int stageIndex})?> loadReportDraft() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? raw = prefs.getString(_key);
  if (raw == null || raw.isEmpty) return null;

  try {
    final Map<String, dynamic> map =
        jsonDecode(raw) as Map<String, dynamic>;
    final int stageIndex = (map['stageIndex'] as num?)?.toInt() ?? 0;
    final int? categoryIndex = (map['categoryIndex'] as num?)?.toInt();
    final String description = map['description'] as String? ?? '';
    final double? lat = (map['latitude'] as num?)?.toDouble();
    final double? lng = (map['longitude'] as num?)?.toDouble();
    final String? address = map['address'] as String?;
    final List<dynamic> paths = map['photoPaths'] is List
        ? (map['photoPaths'] as List<dynamic>)
        : <dynamic>[];
    final List<XFile> photos = paths
        .whereType<String>()
        .where((String p) => p.isNotEmpty && File(p).existsSync())
        .map((String p) => XFile(p))
        .toList();

    final ReportCategory? category = categoryIndex != null &&
            categoryIndex >= 0 &&
            categoryIndex < ReportCategory.values.length
        ? ReportCategory.values[categoryIndex]
        : null;

    final ReportDraft draft = ReportDraft(
      photos: photos,
      category: category,
      description: description,
      latitude: lat,
      longitude: lng,
      address: address,
    );

    return (draft: draft, stageIndex: stageIndex.clamp(0, 3));
  } catch (_) {
    await clearReportDraft();
    return null;
  }
}

/// Clears saved draft. Call after successful submit or when user chooses "Start fresh".
Future<void> clearReportDraft() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(_key);
}

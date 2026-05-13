import 'dart:convert';
import 'dart:io';

import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/report_field_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CreateReportWithLocationDto in OpenAPI matches ReportFieldLimits and enums', () {
    final File openapi = File('../api/openapi/openapi.snapshot.json');
    expect(
      openapi.existsSync(),
      isTrue,
      reason: 'Expected OpenAPI snapshot at ${openapi.absolute.path} (run tests from apps/mobile)',
    );
    final Object? decoded = json.decode(openapi.readAsStringSync());
    expect(decoded, isA<Map<String, dynamic>>());
    final Map<String, dynamic> root = decoded! as Map<String, dynamic>;
    final Map<String, dynamic> components =
        root['components']! as Map<String, dynamic>;
    final Map<String, dynamic> schemas =
        components['schemas']! as Map<String, dynamic>;
    final Map<String, dynamic> dto =
        schemas['CreateReportWithLocationDto']! as Map<String, dynamic>;
    final Map<String, dynamic> props =
        dto['properties']! as Map<String, dynamic>;

    final Map<String, dynamic> title = props['title']! as Map<String, dynamic>;
    expect(title['maxLength'], ReportFieldLimits.maxTitleLength);

    final Map<String, dynamic> description =
        props['description']! as Map<String, dynamic>;
    expect(description['maxLength'], ReportFieldLimits.maxDescriptionLength);

    final Map<String, dynamic> mediaUrls =
        props['mediaUrls']! as Map<String, dynamic>;
    expect(mediaUrls['maxItems'], ReportFieldLimits.maxPhotos);

    final List<dynamic> categoryEnum =
        (props['category']! as Map<String, dynamic>)['enum']! as List<dynamic>;
    final List<String> apiCategory = categoryEnum.cast<String>();
    final List<String> client = ReportCategory.values
        .map((ReportCategory c) => c.apiString)
        .toList()
      ..sort();
    final List<String> sortedApi = List<String>.from(apiCategory)..sort();
    expect(sortedApi, client);

    final Map<String, dynamic> severity =
        props['severity']! as Map<String, dynamic>;
    expect(severity['minimum'], 1);
    expect(severity['maximum'], 5);

    final Map<String, dynamic> cleanup =
        props['cleanupEffort']! as Map<String, dynamic>;
    final List<dynamic> cleanupEnum = cleanup['enum']! as List<dynamic>;
    final List<String> cleanupKeys = cleanupEnum.cast<String>();
    for (final CleanupEffort e in CleanupEffort.values) {
      expect(cleanupKeys, contains(e.apiKey));
    }
  });
}

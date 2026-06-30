import 'dart:convert';
import 'dart:io';

import 'package:feature_reports/src/domain/report_field_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CreateSiteResolutionDto in OpenAPI matches ReportFieldLimits media count',
    () {
      final File openapi = File('../api/openapi/openapi.snapshot.json');
      expect(
        openapi.existsSync(),
        isTrue,
        reason:
            'Expected OpenAPI snapshot at ${openapi.absolute.path} (run tests from apps/mobile)',
      );
      final Object? decoded = json.decode(openapi.readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
      final Map<String, dynamic> root = decoded! as Map<String, dynamic>;
      final Map<String, dynamic> components =
          root['components']! as Map<String, dynamic>;
      final Map<String, dynamic> schemas =
          components['schemas']! as Map<String, dynamic>;
      final Map<String, dynamic> dto =
          schemas['CreateSiteResolutionDto']! as Map<String, dynamic>;
      final Map<String, dynamic> props =
          dto['properties']! as Map<String, dynamic>;

      final Map<String, dynamic> mediaUrls =
          props['mediaUrls']! as Map<String, dynamic>;
      expect(mediaUrls['minItems'], 1);
      expect(mediaUrls['maxItems'], ReportFieldLimits.maxPhotos);

      final Map<String, dynamic> note = props['note']! as Map<String, dynamic>;
      expect(note['maxLength'], 500);
    },
  );
}

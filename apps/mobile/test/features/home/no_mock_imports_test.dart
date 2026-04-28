import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production sources do not import mock_pollution_sites', () async {
    final Directory libDir = Directory('lib');
    expect(await libDir.exists(), isTrue);

    final List<String> offenders = <String>[];
    await for (final FileSystemEntity entity in libDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String normalized = entity.path.replaceAll('\\', '/');
      if (normalized.contains('/lib/dev/')) {
        continue;
      }
      final String content = await entity.readAsString();
      if (content.contains('mock_pollution_sites.dart')) {
        offenders.add(normalized);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Production files importing mock data: ${offenders.join(', ')}',
    );
  });
}

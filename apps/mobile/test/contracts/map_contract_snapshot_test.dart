import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('map contract snapshot has expected keys', () async {
    final File file = File('test/contracts/map_contract_snapshot.json');
    final String raw = await file.readAsString();
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;

    expect(
      json['mapEnvelopeMetaKeys'],
      equals(<String>[
        'signedMediaExpiresAt',
        'serverTime',
        'queryMode',
        'dataVersion',
      ]),
    );
    expect(
      (json['mapListApiRowRequiredKeys'] as List<dynamic>)
          .whereType<String>()
          .toList(),
      equals(<String>[
        'id',
        'latitude',
        'longitude',
        'address',
        'description',
        'status',
        'createdAt',
        'updatedAt',
        'reportCount',
        'latestReportTitle',
        'latestReportDescription',
        'latestReportCategory',
        'latestReportCreatedAt',
        'latestReportNumber',
        'upvotesCount',
        'commentsCount',
        'savesCount',
        'sharesCount',
      ]),
    );
  });
}

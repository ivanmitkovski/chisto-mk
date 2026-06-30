import 'dart:convert';
import 'dart:io';

const String _snapshotPath = 'test/contracts/map_contract_snapshot.json';

const Map<String, Object> _mapContractSnapshot = <String, Object>{
  'mapEnvelopeMetaKeys': <String>[
    'signedMediaExpiresAt',
    'serverTime',
    'queryMode',
    'dataVersion',
  ],
  'mapListApiRowRequiredKeys': <String>[
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
  ],
};

Future<void> main() async {
  final File file = File(_snapshotPath);
  await file.parent.create(recursive: true);
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(_mapContractSnapshot)}\n');
  stdout.writeln('Updated $_snapshotPath');
}

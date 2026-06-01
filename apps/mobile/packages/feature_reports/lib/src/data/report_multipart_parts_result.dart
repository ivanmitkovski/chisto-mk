import 'package:chisto_infrastructure/core/network/api_client.dart';

/// Multipart parts built from local paths, plus skipped-file counts.
class ReportMultipartPartsResult {
  const ReportMultipartPartsResult({
    required this.parts,
    this.skippedMissingCount = 0,
    this.skippedOversizedCount = 0,
  });

  final List<MultipartFileData> parts;
  final int skippedMissingCount;
  final int skippedOversizedCount;

  int get skippedCount => skippedMissingCount + skippedOversizedCount;
}

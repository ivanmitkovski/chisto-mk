/// Local JPEG normalization result before multipart upload.
class ReportPhotoPrepResult {
  const ReportPhotoPrepResult({
    required this.paths,
    this.compressionFallbackCount = 0,
    this.missingSourceCount = 0,
  });

  final List<String> paths;
  final int compressionFallbackCount;

  /// Photos whose source file vanished between draft save and upload (e.g. the
  /// managed photo was orphaned by a prior failed compress). The wizard treats
  /// these as `skipped` so submit can still complete text-only.
  final int missingSourceCount;
}

/// Result of uploading report photos (URLs plus non-fatal warnings).
class ReportPhotoUploadOutcome {
  const ReportPhotoUploadOutcome({
    required this.urls,
    this.skippedPhotoCount = 0,
    this.compressionFallbackCount = 0,
  });

  final List<String> urls;
  final int skippedPhotoCount;
  final int compressionFallbackCount;

  bool get hasWarnings => skippedPhotoCount > 0 || compressionFallbackCount > 0;
}

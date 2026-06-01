/// Local JPEG normalization result before multipart upload.
class ReportPhotoPrepResult {
  const ReportPhotoPrepResult({
    required this.paths,
    this.compressionFallbackCount = 0,
  });

  final List<String> paths;
  final int compressionFallbackCount;
}

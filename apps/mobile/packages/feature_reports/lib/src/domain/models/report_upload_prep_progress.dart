/// JPEG normalization progress before HTTP photo upload (outbox pipeline).
///
/// Lives in domain so presentation can observe upload prep without importing
/// SQLite/outbox data types.
class ReportUploadPrepProgress {
  const ReportUploadPrepProgress({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;
}

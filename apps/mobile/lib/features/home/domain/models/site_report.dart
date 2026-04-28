class SiteReport {
  const SiteReport({
    required this.id,
    required this.reporterName,
    required this.reportedAt,
    required this.title,
    this.description,
    this.imageUrls = const [],
    this.reporterAvatarUrl,
  });

  final String id;
  final String reporterName;
  final String? reporterAvatarUrl;
  final DateTime reportedAt;
  final String title;
  final String? description;
  /// Remote media URLs or local asset paths (trimmed strings; UI maps to image providers).
  final List<String> imageUrls;

  String get reportedAgo {
    final Duration diff = DateTime.now().difference(reportedAt);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'Just now';
  }
}

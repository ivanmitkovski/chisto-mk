/// A distinct person credited as co-reporter on a pollution site (from GET /sites/:id).
class CoReporterProfile {
  const CoReporterProfile({
    required this.displayName,
    this.avatarUrl,
    this.userId,
  });

  final String displayName;
  final String? avatarUrl;
  final String? userId;
}

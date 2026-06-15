import 'package:chisto_infrastructure/core/network/request_cancellation.dart';

class SiteResolutionSubmitResult {
  const SiteResolutionSubmitResult({
    required this.id,
    required this.siteId,
    required this.status,
  });

  final String id;
  final String siteId;
  final String status;
}

class CleanupEvidenceItem {
  const CleanupEvidenceItem({
    required this.id,
    required this.url,
    required this.source,
    required this.createdAt,
    this.caption,
    this.submitterDisplayLabel,
    this.resolutionId,
    this.cleanupEventId,
  });

  final String id;
  final String url;
  final String source;
  final String createdAt;
  final String? caption;
  final String? submitterDisplayLabel;
  final String? resolutionId;
  final String? cleanupEventId;
}

class CleanupEvidenceListResult {
  const CleanupEvidenceListResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<CleanupEvidenceItem> items;
  final int page;
  final int limit;
  final int total;
}

class SiteResolutionListItem {
  const SiteResolutionListItem({
    required this.id,
    required this.siteId,
    required this.status,
    required this.mediaUrls,
    required this.createdAt,
    required this.isSelf,
    this.note,
  });

  final String id;
  final String siteId;
  final String status;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final bool isSelf;
  final String? note;
}

class SiteResolutionListResult {
  const SiteResolutionListResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<SiteResolutionListItem> items;
  final int page;
  final int limit;
  final int total;
}

abstract interface class SiteResolutionRepository {
  Future<List<String>> uploadResolutionPhotos(
    String siteId,
    List<String> filePaths,
  );

  Future<SiteResolutionSubmitResult> submitSiteResolution({
    required String siteId,
    required List<String> mediaUrls,
    String? note,
  });

  Future<CleanupEvidenceListResult> getCleanupEvidence(
    String siteId, {
    int page = 1,
    int limit = 24,
    RequestCancellationToken? cancellation,
  });

  Future<SiteResolutionListResult> listSiteResolutions(
    String siteId, {
    int page = 1,
    int limit = 20,
    RequestCancellationToken? cancellation,
  });
}

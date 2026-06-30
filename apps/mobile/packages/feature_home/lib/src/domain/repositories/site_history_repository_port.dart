import 'package:feature_home/src/domain/models/site_history_entry.dart';

/// Site lifecycle history (`GET /sites/:id/history`).
// ignore: one_member_abstracts, intentional injectable port
abstract class SiteHistoryRepositoryPort {
  Future<SiteHistoryPage> fetchHistory(
    String siteId, {
    int limit = 30,
    String? beforeId,
  });
}

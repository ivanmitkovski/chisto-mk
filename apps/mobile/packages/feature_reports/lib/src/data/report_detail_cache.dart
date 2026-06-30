import 'package:feature_reports/src/domain/models/report_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory cache of recently fetched report details for offline fallback.
class ReportDetailCacheStore {
  final Map<String, ReportDetail> _byId = <String, ReportDetail>{};

  ReportDetail? get(String id) => _byId[id];

  void put(ReportDetail detail) {
    _byId[detail.id] = detail;
  }
}

final reportDetailCacheProvider = Provider<ReportDetailCacheStore>((Ref ref) {
  ref.keepAlive();
  return ReportDetailCacheStore();
});

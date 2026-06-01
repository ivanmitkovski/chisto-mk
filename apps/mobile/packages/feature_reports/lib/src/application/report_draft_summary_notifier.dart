import 'package:feature_reports/src/application/reports_providers.dart';
import 'package:feature_reports/src/domain/models/report_draft_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_draft_summary_notifier.g.dart';

/// Latest wizard draft summary for resume UI (backed by [ReportDraftRepository]).
@riverpod
class ReportDraftSummaryNotifier extends _$ReportDraftSummaryNotifier {
  @override
  Future<ReportDraftSummary> build() async {
    final repo = ref.watch(reportDraftRepositoryProvider);
    return repo.summary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<ReportDraftSummary>();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(reportDraftRepositoryProvider);
      return repo.summary();
    });
  }
}

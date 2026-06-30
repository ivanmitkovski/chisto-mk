import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_reports/src/domain/models/report_list_item.dart';

/// Immutable paging state for "My reports" ([ReportsListController]).
class ReportsListState {
  const ReportsListState({
    this.reports = const <ReportListItem>[],
    this.isLoadingFirstPage = true,
    this.isAppending = false,
    this.loadError,
    this.appendLoadError,
    this.hasMore = true,
  });

  final List<ReportListItem> reports;
  final bool isLoadingFirstPage;
  final bool isAppending;
  final AppError? loadError;
  final AppError? appendLoadError;
  final bool hasMore;

  ReportsListState copyWith({
    List<ReportListItem>? reports,
    bool? isLoadingFirstPage,
    bool? isAppending,
    AppError? loadError,
    bool clearLoadError = false,
    AppError? appendLoadError,
    bool clearAppendLoadError = false,
    bool? hasMore,
  }) {
    return ReportsListState(
      reports: reports ?? this.reports,
      isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
      isAppending: isAppending ?? this.isAppending,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      appendLoadError: clearAppendLoadError
          ? null
          : (appendLoadError ?? this.appendLoadError),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Immutable tab-shell state for [HomeShellController].
class HomeShellState {
  const HomeShellState({
    this.reportIdToOpen,
    this.reportsRefreshTrigger = 0,
    this.isLaunchingReportFlow = false,
  });

  final String? reportIdToOpen;
  final int reportsRefreshTrigger;
  final bool isLaunchingReportFlow;

  HomeShellState copyWith({
    String? reportIdToOpen,
    bool clearReportIdToOpen = false,
    int? reportsRefreshTrigger,
    bool? isLaunchingReportFlow,
  }) {
    return HomeShellState(
      reportIdToOpen: clearReportIdToOpen
          ? null
          : (reportIdToOpen ?? this.reportIdToOpen),
      reportsRefreshTrigger:
          reportsRefreshTrigger ?? this.reportsRefreshTrigger,
      isLaunchingReportFlow:
          isLaunchingReportFlow ?? this.isLaunchingReportFlow,
    );
  }
}

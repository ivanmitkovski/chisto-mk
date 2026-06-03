import 'dart:async';

import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_events/feature_events.dart';
import 'package:feature_home/src/application/home_shell_state.dart';
import 'package:feature_home/src/presentation/utils/open_report_linked_pollution_site.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_shell_controller.g.dart';

/// Shared state for the signed-in tab shell (map focus, reports FAB, coach tour).
@Riverpod(keepAlive: true)
class HomeShellController extends _$HomeShellController {
  final GlobalKey feedKey = GlobalKey();
  final GlobalKey<EventsFeedScreenState> eventsFeedKey =
      GlobalKey<EventsFeedScreenState>();
  final ValueNotifier<String?> mapPendingSiteFocus = ValueNotifier<String?>(
    null,
  );
  final HomeShellCoachKeys coachKeys = HomeShellCoachKeys();

  @override
  HomeShellState build() {
    ref.onDispose(mapPendingSiteFocus.dispose);
    return const HomeShellState();
  }

  String? get reportIdToOpen => state.reportIdToOpen;
  int get reportsRefreshTrigger => state.reportsRefreshTrigger;
  bool get isLaunchingReportFlow => state.isLaunchingReportFlow;

  CoachTourController get coachTour =>
      ref.read(coachTourControllerProvider.notifier);

  void requestShowSiteOnMap(String siteId, GoRouter router) {
    mapPendingSiteFocus.value = siteId;
    router.go('/map');
  }

  Widget buildReportsTab(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? _) {
        final HomeShellState shellState = ref.watch(
          homeShellControllerProvider,
        );
        return ReportsListScreen(
          initialReportIdToOpen: shellState.reportIdToOpen,
          onReportOpened: () {
            ref
                .read(homeShellControllerProvider.notifier)
                .clearReportIdToOpen();
          },
          refreshTrigger: shellState.reportsRefreshTrigger,
          onShowSiteOnMap: (String siteId) =>
              requestShowSiteOnMap(siteId, GoRouter.of(context)),
          onOpenLinkedPollutionSiteDetail: (String siteId, snapshot) =>
              openReportLinkedPollutionSiteDetail(
                context: context,
                ref: ref,
                siteId: siteId,
                snapshot: snapshot,
              ),
        );
      },
    );
  }

  Future<void> handleCentralFabPressed(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (state.isLaunchingReportFlow) {
      return;
    }
    state = state.copyWith(isLaunchingReportFlow: true);

    try {
      final bool canProceed = await ReportEntryFlow.ensureReportingAllowed(
        context,
        ref: ref,
      );
      if (!canProceed || !context.mounted) {
        return;
      }
      final ReportDraftSummary draftSummary = ref
          .read(reportDraftRepositoryProvider)
          .summaryListenable
          .value;
      if (draftSummary.hasDraft) {
        final CentralFabDraftChoice? choice =
            await ReportEntryFlow.promptDraftChoiceIfNeeded(
              context: context,
              summary: draftSummary,
            );
        if (!context.mounted) {
          return;
        }
        if (choice == CentralFabDraftChoice.cancel || choice == null) {
          return;
        }
        if (choice == CentralFabDraftChoice.continueDraft) {
          final Object? navResult = await ReportEntryFlow.openNewReportWizard(
            context,
          );
          if (navResult != null && context.mounted) {
            _afterReportWizard(context, navResult);
          }
          return;
        }
      }
      final Object? navResult = await ReportEntryFlow.openCameraThenNewReport(
        context: context,
      );
      if (navResult != null && context.mounted) {
        _afterReportWizard(context, navResult);
      }
    } finally {
      state = state.copyWith(isLaunchingReportFlow: false);
    }
  }

  void _afterReportWizard(BuildContext context, Object navResult) {
    ReportEntryFlow.handleNewReportWizardPopResult(
      navResult,
      onViewSubmittedReport: (String reportId) {
        state = state.copyWith(
          reportsRefreshTrigger: state.reportsRefreshTrigger + 1,
          reportIdToOpen: reportId,
        );
        GoRouter.of(context).go('/reports');
      },
      onViewReportsList: () {
        state = state.copyWith(
          reportsRefreshTrigger: state.reportsRefreshTrigger + 1,
          clearReportIdToOpen: navResult is! NewReportWizardViewReport,
        );
        GoRouter.of(context).go('/reports');
      },
    );
  }

  void clearReportIdToOpen() {
    state = state.copyWith(clearReportIdToOpen: true);
  }

  void applyInitialFocus({
    String? mapSiteIdToFocus,
    bool startCoachTour = false,
  }) {
    final String? focusId = mapSiteIdToFocus?.trim();
    if (startCoachTour && (focusId == null || focusId.isEmpty)) {
      unawaited(coachTour.startIfEligible());
    }
    if (focusId != null && focusId.isNotEmpty) {
      mapPendingSiteFocus.value = focusId;
    }
  }
}

HomeShellController get homeShellController =>
    readRoot(homeShellControllerProvider.notifier);

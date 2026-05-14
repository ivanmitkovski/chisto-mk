import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/screens/events_feed_screen.dart'
    show EventsFeedScreenState;
import 'package:chisto_mobile/features/home/presentation/navigation/home_shell_router.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/home_shell_coach_keys.dart';
import 'package:chisto_mobile/features/onboarding/application/coach_tour_controller.dart';
import 'package:chisto_mobile/features/onboarding/debug/coach_tour_debug.dart';
import 'package:chisto_mobile/features/home/presentation/utils/open_report_linked_pollution_site.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/draft/draft_choice_sheet.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_summary_projector.dart';
import 'package:chisto_mobile/features/reports/presentation/flow/report_entry_flow.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/reports_list_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.initialTabIndex = 0,
    this.mapSiteIdToFocus,
    this.startCoachTour = false,
  });

  final int initialTabIndex;

  /// When set, opens the map tab and focuses this site (deep link / notification).
  final String? mapSiteIdToFocus;

  /// When true (e.g. after sign-up), [CoachTourController] may open the overlay on first frame.
  final bool startCoachTour;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String? _reportIdToOpen;
  int _reportsRefreshTrigger = 0;
  final GlobalKey _feedKey = GlobalKey();
  final GlobalKey<EventsFeedScreenState> _eventsFeedKey =
      GlobalKey<EventsFeedScreenState>();
  bool _isLaunchingReportFlow = false;

  final HomeShellCoachKeys _coachKeys = HomeShellCoachKeys();
  late final CoachTourController _coachTour;

  final ValueNotifier<String?> _mapPendingSiteFocus = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<bool> _isLaunchingReportNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<int> _reportsRefreshNotifier = ValueNotifier<int>(0);

  late final GoRouter _homeRouter;

  @override
  void initState() {
    super.initState();
    _coachTour = CoachTourController(
      repository: ServiceLocator.instance.featureGuideRepository,
      debugForceSessionEligible: CoachTourDebug.forceSessionEligible,
    );
    final int tab = widget.initialTabIndex.clamp(0, 3);
    final String? focusId = widget.mapSiteIdToFocus?.trim();
    final String initialLocation =
        focusId != null && focusId.isNotEmpty && tab == 2
        ? '/map'
        : homeShellTabIndexToLocation(tab);

    _homeRouter = buildHomeShellGoRouter(
      initialLocation: initialLocation,
      mapPendingSiteFocus: _mapPendingSiteFocus,
      feedKey: _feedKey,
      eventsFeedKey: _eventsFeedKey,
      reportsPageBuilder: (BuildContext context) {
        return ReportsListScreen(
          initialReportIdToOpen: _reportIdToOpen,
          onReportOpened: () => setState(() => _reportIdToOpen = null),
          refreshTrigger: _reportsRefreshTrigger,
          onShowSiteOnMap: _requestShowSiteOnMap,
          onOpenLinkedPollutionSiteDetail: (String siteId, snapshot) =>
              openReportLinkedPollutionSiteDetail(
                context: context,
                siteId: siteId,
                snapshot: snapshot,
              ),
        );
      },
      onCentralFabPressed: _handleCentralFabPressed,
      isLaunchingReportFlow: _isLaunchingReportNotifier,
      refreshListenable: Listenable.merge(<Listenable>[
        _reportsRefreshNotifier,
        _isLaunchingReportNotifier,
      ]),
      coachKeys: _coachKeys,
      coachTour: _coachTour,
    );

    final bool focusIsSet = focusId != null && focusId.isNotEmpty;
    if (widget.startCoachTour && !focusIsSet) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await _coachTour.startIfEligible();
      });
    }

    if (focusId != null && focusId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapPendingSiteFocus.value = focusId;
        }
      });
    }
  }

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? newFocus = widget.mapSiteIdToFocus?.trim();
    final String? oldFocus = oldWidget.mapSiteIdToFocus?.trim();
    if (newFocus != null &&
        newFocus.isNotEmpty &&
        newFocus != (oldFocus ?? '')) {
      if (_coachTour.isVisible) {
        _coachTour.hideWithoutPersisting();
      }
    }
  }

  @override
  void dispose() {
    _homeRouter.dispose();
    _coachTour.dispose();
    _mapPendingSiteFocus.dispose();
    _isLaunchingReportNotifier.dispose();
    _reportsRefreshNotifier.dispose();
    super.dispose();
  }

  void _requestShowSiteOnMap(String siteId) {
    _mapPendingSiteFocus.value = siteId;
    _homeRouter.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    return Router.withConfig(
      restorationScopeId: 'homeShellRouter',
      config: _homeRouter,
    );
  }

  Future<void> _handleCentralFabPressed(
    BuildContext context,
    int tabIndex,
  ) async {
    if (tabIndex == 3) {
      AppHaptics.softTransition();
      final EcoEvent? created = await EventsNavigation.openCreate(context);
      if (!context.mounted) {
        return;
      }
      if (created != null) {
        await EventsNavigation.openDetail(context, eventId: created.id);
      }
      return;
    }

    if (_isLaunchingReportFlow) {
      return;
    }

    setState(() {
      _isLaunchingReportFlow = true;
    });
    _isLaunchingReportNotifier.value = true;

    try {
      final bool canProceed = await ReportEntryFlow.ensureReportingAllowed(
        context,
      );
      if (!canProceed) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      final ReportDraftSummary draftSummary =
          ServiceLocator.instance.reportDraftRepository.summaryListenable.value;
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
          AppHaptics.softTransition();
          final Object? navResult = await ReportEntryFlow.openNewReportWizard(
            context,
          );
          if (navResult != null && context.mounted) {
            setState(() {
              _homeRouter.go('/reports');
              _reportsRefreshTrigger++;
              _reportsRefreshNotifier.value = _reportsRefreshTrigger;
              if (navResult is String) {
                _reportIdToOpen = navResult;
              }
            });
          }
          return;
        }
      }
      final Object? navResult = await ReportEntryFlow.openCameraThenNewReport(
        context: context,
      );
      if (navResult != null && context.mounted) {
        setState(() {
          _homeRouter.go('/reports');
          _reportsRefreshTrigger++;
          _reportsRefreshNotifier.value = _reportsRefreshTrigger;
          if (navResult is String) {
            _reportIdToOpen = navResult;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingReportFlow = false;
        });
        _isLaunchingReportNotifier.value = false;
      }
    }
  }
}

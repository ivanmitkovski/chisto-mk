import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/event_offline_work_coordinator.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_scroll_interaction.dart';
import 'package:chisto_mobile/features/events/presentation/screens/field_mode_screen.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/offline_work_hub_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/organizer_dashboard/organizer_event_summary_card.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

/// Full-screen list of the current user's organised events, grouped by status.
class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  final EventsRepository _eventsStore = EventsRepositoryRegistry.instance;

  bool _isLoading = true;
  AppError? _loadError;
  List<EcoEvent> _myEvents = const <EcoEvent>[];

  @override
  void initState() {
    super.initState();
    _eventsStore.addListener(_onEventsUpdated);
    unawaited(_loadMyEvents());
  }

  @override
  void dispose() {
    _eventsStore.removeListener(_onEventsUpdated);
    super.dispose();
  }

  void _onEventsUpdated() {
    if (mounted) _refreshFromStore();
  }

  void _refreshFromStore() {
    setState(() {
      _myEvents = _eventsStore.events
          .where((EcoEvent e) => e.isOrganizer)
          .toList();
    });
  }

  Future<void> _loadMyEvents() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await _eventsStore.refreshEvents(
        params: const EcoEventSearchParams(
          statuses: <EcoEventStatus>{EcoEventStatus.upcoming},
        ),
      );
      // Also load all statuses for a complete picture.
      await _eventsStore.refreshEvents();
      _refreshFromStore();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _loadError = AppError.network(cause: e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    eventsPullRefreshHaptic(context);
    try {
      await _eventsStore.refreshEvents();
      _refreshFromStore();
    } on Object catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsFeedRefreshFailed,
          type: AppSnackType.warning,
        );
      }
    }
  }

  List<EcoEvent> _sectionEvents(EcoEventStatus status) =>
      _myEvents.where((EcoEvent e) => e.status == status).toList()
        ..sort((EcoEvent a, EcoEvent b) => a.date.compareTo(b.date));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (BuildContext context) {
            final Widget scrollView = CustomScrollView(
              physics: eventsListScrollPhysics(context),
              slivers: <Widget>[
                if (eventsUseCupertinoSystemEffects(context))
                  CupertinoSliverRefreshControl(onRefresh: _onRefresh),
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: <Widget>[
                        const AppBackButton(),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.l10n.eventsOrganizerDashboardTitle,
                            style: AppTypography.eventsDetailHeadline(
                              Theme.of(context).textTheme,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<EventOfflineWorkSnapshot>(
                          valueListenable:
                              EventOfflineWorkCoordinator.instance.snapshot,
                          builder:
                              (
                                BuildContext context,
                                EventOfflineWorkSnapshot snap,
                                Widget? _,
                              ) {
                                if (snap.totalWorkItems <= 0) {
                                  return const SizedBox.shrink();
                                }
                                final String badge = snap.totalWorkItems > 99
                                    ? '99+'
                                    : '${snap.totalWorkItems}';
                                return IconButton(
                                  tooltip:
                                      context.l10n.eventsOfflineWorkHubTitle,
                                  onPressed: () =>
                                      showOfflineWorkHubSheet(context),
                                  icon: Badge(
                                    label: Text(
                                      badge,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.cloud_sync_outlined,
                                    ),
                                  ),
                                );
                              },
                        ),
                        IconButton(
                          tooltip: context.l10n.eventsFieldModeTitle,
                          icon: const Icon(CupertinoIcons.arrow_2_circlepath),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const FieldModeScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (_loadError != null && _myEvents.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            CupertinoIcons.exclamationmark_circle,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.l10n.eventsFeedInitialLoadFailed,
                            style: AppTypography.eventsBodyMuted(
                              Theme.of(context).textTheme,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: _loadMyEvents,
                            child: Text(context.l10n.eventsFeedRefreshFailed),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_myEvents.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.calendar_badge_plus,
                              size: 32,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            context.l10n.eventsOrganizerDashboardEmpty,
                            style: AppTypography.eventsBodyMuted(
                              Theme.of(context).textTheme,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            onPressed: () =>
                                EventsNavigation.openCreate(context),
                            icon: const Icon(CupertinoIcons.add, size: 16),
                            label: Text(
                              context.l10n.eventsOrganizerDashboardEmptyAction,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...<Widget>[
                  _buildSection(
                    context,
                    label:
                        context.l10n.eventsOrganizerDashboardSectionInProgress,
                    events: _sectionEvents(EcoEventStatus.inProgress),
                  ),
                  _buildSection(
                    context,
                    label: context.l10n.eventsOrganizerDashboardSectionUpcoming,
                    events: _sectionEvents(EcoEventStatus.upcoming),
                  ),
                  _buildSection(
                    context,
                    label:
                        context.l10n.eventsOrganizerDashboardSectionCompleted,
                    events: _sectionEvents(EcoEventStatus.completed),
                  ),
                  _buildSection(
                    context,
                    label:
                        context.l10n.eventsOrganizerDashboardSectionCancelled,
                    events: _sectionEvents(EcoEventStatus.cancelled),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              ],
            );
            return eventsUseCupertinoSystemEffects(context)
                ? scrollView
                : RefreshIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.2,
                    displacement: 40,
                    onRefresh: _onRefresh,
                    child: scrollView,
                  );
          },
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String label,
    required List<EcoEvent> events,
  }) {
    if (events.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverList(
      delegate: SliverChildListDelegate(<Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Text(
            label,
            style: AppTypography.eventsMicroSectionHeading(
              Theme.of(context).textTheme,
            ).copyWith(letterSpacing: 0.3, fontWeight: FontWeight.w700),
          ),
        ),
        ...events.map(
          (EcoEvent event) => OrganizerEventSummaryCard(
            key: ValueKey<String>(event.id),
            event: event,
            onTap: () =>
                EventsNavigation.openDetail(context, eventId: event.id),
            onCheckIn: () => EventsNavigation.openOrganizerCheckIn(
              context,
              eventId: event.id,
            ),
            onEvidence: () => EventsNavigation.openCleanupEvidence(
              context,
              eventId: event.id,
            ),
          ),
        ),
      ], addAutomaticKeepAlives: false),
    );
  }
}

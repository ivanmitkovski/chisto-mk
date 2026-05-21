library;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/widgets/state_rebuild_mixin.dart';
import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/core/providers/events_providers.dart';
import 'package:chisto_mobile/core/providers/notifications_providers.dart';
import 'package:chisto_mobile/core/providers/root_container.dart';
import 'package:chisto_mobile/features/events/presentation/utils/organizer_end_soon_local_controller.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/extend_event_end_sheet.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/events/data/field_mode_queue.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_join_toggle_result.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_export.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_scroll_interaction.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/after_photos_gallery.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/detail_content.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/feedback_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_detail_cta_presentation.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/hero_image_bar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_layout.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_not_found_view.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/reminder_picker_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/screens/edit_event_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/sticky_bottom_cta.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail_skeleton.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/widgets/molecules/animated_phase_switcher.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_button.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_refresh_indicator.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_snack.dart';

part 'event_detail/event_detail_refresh_coordinator.dart';
part 'event_detail/event_detail_organizer_actions.dart';
part 'event_detail/event_detail_attendee_actions.dart';
part 'event_detail/event_detail_scroll_shell.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.enableThumbnailHero = false,
    @visibleForTesting this.eventsRepository,
  });

  final String eventId;

  /// When false, the cover is not wrapped in [Hero] (used when replacing detail for
  /// another event to avoid `_HeroFlight.divert` with mismatched tags).
  final bool enableThumbnailHero;

  /// Pinned repository for widget tests; production uses [EventsRepositoryRegistry].
  @visibleForTesting
  final EventsRepository? eventsRepository;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with WidgetsBindingObserver, StateRebuildMixin {
  EventsRepository get _eventsStore =>
      widget.eventsRepository ?? EventsRepositoryRegistry.instance;
  final EventFeedbackLocalCache _feedbackCache =
      const EventFeedbackLocalCache();
  static const Duration _detailResumeRefreshTtlDefault = Duration(seconds: 45);
  static const Duration _detailResumeRefreshTtlHot = Duration(seconds: 15);

  EventFeedbackSnapshot? _feedbackSnapshot;
  bool _detailPrefetchDone = false;
  bool _detailMissing = false;
  DateTime? _lastDetailRefreshAt;
  Future<void>? _detailPrefetchInFlight;
  bool _ctaMutationBusy = false;
  int _chatUnreadCount = 0;
  final OrganizerEndSoonLocalController _organizerEndSoonLocal =
      OrganizerEndSoonLocalController();
  Timer? _joinWindowTicker;
  final ScrollController _detailScrollController = ScrollController();

  /// True once scroll offset passes the fully-collapsed hero height (body
  /// scrolling under the pinned toolbar). Feeds [HeroImageBar.innerBoxIsScrolled].
  bool _heroCollapsedEnoughForBodyScroll = false;

  /// True when a forced refresh failed while we still show a cached [EcoEvent].
  bool _localDetailRefreshFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _eventsStore.loadInitialIfNeeded();
    _eventsStore.addListener(_onStoreChanged);
    _loadFeedback();
    unawaited(_prefetchDetailDeduped());
    _detailScrollController.addListener(_onDetailScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureJoinWindowTicker();
        _onDetailScroll();
      }
    });
  }

  @override
  void didUpdateWidget(EventDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      if (_detailScrollController.hasClients) {
        _detailScrollController.jumpTo(0);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _detailScrollController.hasClients) {
            _detailScrollController.jumpTo(0);
          }
        });
      }
      if (_heroCollapsedEnoughForBodyScroll) {
        setState(() => _heroCollapsedEnoughForBodyScroll = false);
      }
    }
  }

  @override
  void dispose() {
    _detailScrollController.removeListener(_onDetailScroll);
    _detailScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _eventsStore.removeListener(_onStoreChanged);
    final AppBootstrap bootstrap = readRoot(appBootstrapProvider);
    if (bootstrap.isInitialized) {
      unawaited(
        _organizerEndSoonLocal.dispose(
          readRoot(pushNotificationServiceProvider),
        ),
      );
    }
    _joinWindowTicker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshDetailIfStale());
      _ensureJoinWindowTicker();
    }
  }

  @override
  Widget build(BuildContext context) => buildEventDetailScrollShell(context);
}

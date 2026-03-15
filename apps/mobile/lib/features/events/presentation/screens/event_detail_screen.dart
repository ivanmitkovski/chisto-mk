import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_export.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/after_photos_gallery.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/detail_content.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/feedback_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/hero_image_bar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/reminder_picker_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/sticky_bottom_cta.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:share_plus/share_plus.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventsRepository _eventsStore = EventsRepositoryRegistry.instance;
  final EventFeedbackLocalCache _feedbackCache = const EventFeedbackLocalCache();
  EventFeedbackSnapshot? _feedbackSnapshot;

  @override
  void initState() {
    super.initState();
    _eventsStore.loadInitialIfNeeded();
    _eventsStore.addListener(_onStoreChanged);
    _loadFeedback();
  }

  @override
  void dispose() {
    _eventsStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) {
      return;
    }
    void applyUpdate() {
      if (!mounted) {
        return;
      }
      setState(() {});
    }
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
      return;
    }
    applyUpdate();
  }

  Future<void> _loadFeedback() async {
    final EventFeedbackSnapshot? snapshot =
        await _feedbackCache.read(widget.eventId);
    if (!mounted) {
      return;
    }
    setState(() {
      _feedbackSnapshot = snapshot;
    });
  }

  Future<void> _editFeedback(EcoEvent event) async {
    final EventFeedbackSnapshot? current = _feedbackSnapshot;
    final EventFeedbackSnapshot? updated =
        await _showFeedbackSheet(event, current);
    if (!mounted || updated == null) {
      return;
    }
    await _feedbackCache.write(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _feedbackSnapshot = updated;
    });
    AppSnack.show(
      context,
      message: current == null
          ? 'Impact summary saved.'
          : 'Impact summary updated.',
      type: AppSnackType.success,
    );
  }

  Future<EventFeedbackSnapshot?> _showFeedbackSheet(
    EcoEvent event,
    EventFeedbackSnapshot? current,
  ) async {
    return showModalBottomSheet<EventFeedbackSnapshot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (BuildContext _) => FeedbackSheetContent(
        event: event,
        current: current,
      ),
    );
  }

  Future<void> _handleShare(EcoEvent event) async {
    AppHaptics.tap();
    const String baseUrl = 'https://chisto.mk';
    final String deepLink = '$baseUrl/events/${event.id}';
    final String text =
        '${event.title}\n${event.formattedDate} (${event.formattedTimeRange})\n${event.siteName}\n\n$deepLink';
    await Share.share(text, subject: event.title);
    if (mounted) {
      AppSnack.show(
        context,
        message: 'Event shared.',
        type: AppSnackType.success,
      );
    }
  }

  void _handleStartEvent(EcoEvent event) {
    final bool changed = _eventsStore.updateStatus(event.id, EcoEventStatus.inProgress);
    if (!changed) {
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: 'Unable to start event from current state.',
        type: AppSnackType.warning,
      );
      return;
    }
    final EcoEvent startedEvent = _eventsStore.findById(event.id) ??
        event.copyWith(status: EcoEventStatus.inProgress);
    EventsNavigation.openOrganizerCheckIn(context, eventId: startedEvent.id);
  }

  void _handleManageCheckIn(EcoEvent event) {
    if (event.status != EcoEventStatus.inProgress) {
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: 'Check-in is available only while event is in progress.',
        type: AppSnackType.warning,
      );
      return;
    }
    EventsNavigation.openOrganizerCheckIn(context, eventId: event.id);
  }

  void _handleOpenCleanupEvidence(EcoEvent event) {
    if (!event.isOrganizer || event.status != EcoEventStatus.completed) {
      AppHaptics.warning();
      return;
    }
    AppHaptics.softTransition();
    EventsNavigation.openCleanupEvidence(context, eventId: event.id);
  }

  void _handleToggleJoin(EcoEvent event) {
    if (!event.isJoined &&
        event.maxParticipants != null &&
        event.participantCount >= event.maxParticipants!) {
      AppHaptics.warning();
      AppSnack.show(context, message: 'This event is full.', type: AppSnackType.warning);
      return;
    }
    final bool changed = _eventsStore.toggleJoin(event.id);
    if (!changed) {
      AppHaptics.warning();
      return;
    }
    final EcoEvent? updated = _eventsStore.findById(event.id);
    AppSnack.show(
      context,
      message: (updated?.isJoined ?? false)
          ? 'You joined this eco action.'
          : 'You left this eco action.',
      type: AppSnackType.success,
    );
  }

  void _handleToggleReminder(EcoEvent event) {
    AppHaptics.tap();
    if (!event.isJoined) {
      AppSnack.show(
        context,
        message: 'Join the event first to set reminders.',
        type: AppSnackType.warning,
      );
      return;
    }
    if (event.reminderEnabled) {
      final bool changed = _eventsStore.setReminder(
        eventId: event.id,
        enabled: false,
        reminderAt: null,
      );
      if (changed) {
        AppSnack.show(
          context,
          message: 'Reminder disabled.',
          type: AppSnackType.success,
        );
      }
      return;
    }

    _handleEnableReminder(event);
  }

  Future<void> _handleEnableReminder(EcoEvent event) async {
    final DateTime? selectedReminder = await ReminderPickerSheet.show(context, event);
    if (!mounted || selectedReminder == null) {
      return;
    }
    final bool changed = _eventsStore.setReminder(
      eventId: event.id,
      enabled: true,
      reminderAt: selectedReminder,
    );
    if (!changed) {
      return;
    }
    AppSnack.show(
      context,
      message: 'Reminder set for ${ReminderPickerSheet.formatReminderLabel(selectedReminder)}.',
      type: AppSnackType.success,
    );
  }

  Future<void> _handleAddToCalendar(EcoEvent event) async {
    AppHaptics.softTransition();
    try {
      await EventCalendarExport.addToCalendar(event);
      if (!mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: 'Event added to your calendar.',
        type: AppSnackType.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: 'Could not add to calendar. Try again.',
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _handleOpenAttendeeCheckIn(EcoEvent event) async {
    if (event.isCheckedIn) {
      AppSnack.show(
        context,
        message: 'You are already checked in.',
        type: AppSnackType.success,
      );
      return;
    }
    if (!event.canOpenAttendeeCheckIn) {
      AppSnack.show(
        context,
        message: 'Organizer has paused check-in for now.',
        type: AppSnackType.warning,
      );
      return;
    }
    AppHaptics.softTransition();
    final bool? success = await EventsNavigation.openAttendeeQrScanner(
      context,
      eventId: event.id,
    );
    if (!mounted || success != true) {
      return;
    }
    AppSnack.show(
      context,
      message: 'Check-in complete.',
      type: AppSnackType.success,
    );
  }

  void _openFullscreenGallery(BuildContext context, EcoEvent event, int initialIndex) {
    AppHaptics.softTransition();
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) => FullscreenGalleryPage(
          event: event,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EcoEvent? event = _eventsStore.findById(widget.eventId);
    if (event == null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
          title: const Text('Event not found'),
        ),
        body: const Center(
          child: Text('This event is no longer available.'),
        ),
      );
    }

    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    const double primaryHeight = 56;
    const double secondaryHeight = 54;
    final double ctaHeight = AppSpacing.md +
        primaryHeight +
        AppSpacing.sm +
        secondaryHeight +
        AppSpacing.md +
        bottomSafe;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Semantics(
        label: 'Event detail: ${event.title}',
        child: Stack(
        children: <Widget>[
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              HeroImageBar(
                event: event,
                onShare: () => _handleShare(event),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    ctaHeight + AppSpacing.lg,
                  ),
                  child: DetailContent(
                    event: event,
                    onToggleReminder: () => _handleToggleReminder(event),
                    onExportCalendar: () => _handleAddToCalendar(event),
                    feedbackSnapshot: _feedbackSnapshot,
                    onEditFeedback: () => _editFeedback(event),
                    onImageTap: (int index) => _openFullscreenGallery(context, event, index),
                  ),
                ),
              ),
            ],
          ),
          StickyBottomCTA(
            event: event,
            onToggleJoin: () => _handleToggleJoin(event),
            onToggleReminder: () => _handleToggleReminder(event),
            onStartEvent: () => _handleStartEvent(event),
            onManageCheckIn: () => _handleManageCheckIn(event),
            onOpenAttendeeCheckIn: () => _handleOpenAttendeeCheckIn(event),
            onOpenCleanupEvidence: () => _handleOpenCleanupEvidence(event),
          ),
        ],
      ),
      ),
    );
  }
}

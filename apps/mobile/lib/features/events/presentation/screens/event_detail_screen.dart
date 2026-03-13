import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_export.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:share_plus/share_plus.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';

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
    final TextEditingController notesController = TextEditingController(
      text: current?.notes ?? '',
    );
    try {
      return await showModalBottomSheet<EventFeedbackSnapshot>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.panelBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
        ),
        builder: (BuildContext sheetContext) {
          int rating = current?.rating ?? 5;
          int bags = current?.bagsCollected ?? 3;
          double hours = current?.volunteerHours ?? 2;
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setLocalState) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Post-event feedback',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'How was the event?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          children: List<Widget>.generate(5, (int index) {
                            final int v = index + 1;
                            return ChoiceChip(
                              selected: rating == v,
                              label: Text('$v★'),
                              onSelected: (_) => setLocalState(() => rating = v),
                            );
                          }),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Bags collected',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: <Widget>[
                            IconButton(
                              onPressed: bags > 0
                                  ? () => setLocalState(() => bags -= 1)
                                  : null,
                              icon: const Icon(CupertinoIcons.minus_circle),
                            ),
                            Text(
                              '$bags',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            IconButton(
                              onPressed: () => setLocalState(() => bags += 1),
                              icon: const Icon(CupertinoIcons.plus_circle),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Volunteer hours: ${hours.toStringAsFixed(1)}h',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Slider(
                          value: hours,
                          min: 0.5,
                          max: 12,
                          divisions: 23,
                          onChanged: (double value) =>
                              setLocalState(() => hours = value),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'What worked well? Any notes for next time?',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                EventFeedbackSnapshot(
                                  eventId: event.id,
                                  rating: rating,
                                  bagsCollected: bags,
                                  volunteerHours: hours,
                                  notes: notesController.text.trim(),
                                  createdAt: DateTime.now(),
                                ),
                              );
                            },
                            child: const Text('Save impact summary'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      notesController.dispose();
    }
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
    final DateTime? selectedReminder = await _showReminderPicker(event);
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
      message: 'Reminder set for ${_formatReminderLabel(selectedReminder)}.',
      type: AppSnackType.success,
    );
  }

  Future<DateTime?> _showReminderPicker(EcoEvent event) async {
    final DateTime now = DateTime.now();
    final DateTime start = event.startDateTime;
    final List<({String label, Duration before})> presets =
        <({String label, Duration before})>[
      (label: '1 day before', before: const Duration(days: 1)),
      (label: '3 hours before', before: const Duration(hours: 3)),
      (label: '1 hour before', before: const Duration(hours: 1)),
      (label: '30 minutes before', before: const Duration(minutes: 30)),
    ];

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose reminder time',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event starts at ${event.formattedTimeRange} on ${event.formattedDate}.',
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...presets.map((({Duration before, String label}) preset) {
                  final DateTime candidate = start.subtract(preset.before);
                  final bool enabled = candidate.isAfter(now);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(preset.label),
                    subtitle: Text(
                      enabled
                          ? _formatReminderLabel(candidate)
                          : 'Unavailable for this event time',
                    ),
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                    enabled: enabled,
                    onTap: enabled
                        ? () => Navigator.of(sheetContext).pop(candidate)
                        : null,
                  );
                }),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Custom date and time'),
                  subtitle: const Text('Pick a specific reminder moment'),
                  trailing: const Icon(CupertinoIcons.calendar_badge_plus, size: 18),
                  onTap: () async {
                    final DateTime? custom = await _pickCustomReminderDateTime(
                      context: sheetContext,
                      eventStart: start,
                    );
                    if (!sheetContext.mounted || custom == null) {
                      return;
                    }
                    Navigator.of(sheetContext).pop(custom);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<DateTime?> _pickCustomReminderDateTime({
    required BuildContext context,
    required DateTime eventStart,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = eventStart.subtract(const Duration(minutes: 1));
    if (lastDate.isBefore(firstDate)) {
      return null;
    }
    final DateTime initialDate = firstDate.isBefore(lastDate)
        ? firstDate.add(const Duration(hours: 1))
        : firstDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
    );
    if (pickedDate == null || !context.mounted) {
      return null;
    }
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) {
      return null;
    }
    final DateTime picked = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    if (picked.isBefore(now) || !picked.isBefore(eventStart)) {
      return null;
    }
    return picked;
  }

  String _formatReminderLabel(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(dateTime.day)}/${two(dateTime.month)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}';
  }

  Future<void> _handleAddToCalendar(EcoEvent event) async {
    AppHaptics.softTransition();
    try {
      await EventCalendarExport.shareEvent(event);
      if (!mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: 'Calendar file ready to share.',
        type: AppSnackType.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: 'Could not create calendar file. Try again.',
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
        builder: (BuildContext context) => _FullscreenGalleryPage(
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
    final double ctaHeight = 56 + AppSpacing.md * 2 + bottomSafe;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Semantics(
        label: 'Event detail: ${event.title}',
        child: Stack(
        children: <Widget>[
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              _HeroImageBar(
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
                  child: _DetailContent(
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
          _StickyBottomCTA(
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

// ---------------------------------------------------------------------------
// Hero image with app bar
// ---------------------------------------------------------------------------

class _HeroImageBar extends StatelessWidget {
  const _HeroImageBar({
    required this.event,
    required this.onShare,
  });

  final EcoEvent event;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.panelBackground,
      leading: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Center(child: AppBackButton()),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.appBackground.withValues(alpha: 0.85),
            child: IconButton(
              iconSize: 18,
              tooltip: 'Share event',
              onPressed: onShare,
              icon: const Icon(
                CupertinoIcons.share,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double expandRatio = ((constraints.maxHeight - kToolbarHeight) /
                  (260 - kToolbarHeight))
              .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Hero(
                  tag: 'event-thumb-${event.id}',
                  child: Transform.scale(
                    scale: 1.0 + (1.0 - expandRatio) * 0.05,
                    child: Image.asset(
                      event.siteImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.inputFill),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.35 + (1 - expandRatio) * 0.2),
                      ],
                    ),
                  ),
                ),
                if (event.status == EcoEventStatus.upcoming)
                  Positioned(
                    left: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: Opacity(
                      opacity: expandRatio,
                      child: _CountdownBadge(event: event),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.event});
  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final Duration diff = event.startDateTime.difference(DateTime.now());
    if (diff.isNegative) return const SizedBox.shrink();

    final String label;
    if (diff.inDays > 0) {
      label = 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      label = 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      label = 'Starts in ${diff.inMinutes}m';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(CupertinoIcons.clock, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail content with staggered reveal
// ---------------------------------------------------------------------------

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.event,
    required this.onToggleReminder,
    required this.onExportCalendar,
    required this.feedbackSnapshot,
    required this.onEditFeedback,
    required this.onImageTap,
  });

  final EcoEvent event;
  final VoidCallback onToggleReminder;
  final VoidCallback onExportCalendar;
  final EventFeedbackSnapshot? feedbackSnapshot;
  final VoidCallback onEditFeedback;
  final ValueChanged<int> onImageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _StaggeredSection(
          delay: 0,
          child: _TitleSection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StaggeredSection(
          delay: 50,
          child: _LocationChip(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StaggeredSection(
          delay: 100,
          child: _DateTimeSection(
            event: event,
            onExportCalendar: onExportCalendar,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StaggeredSection(
          delay: 150,
          child: _CategorySection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StaggeredSection(
          delay: 200,
          child: _EventDetailsGrid(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (event.gear.isNotEmpty) ...<Widget>[
          _StaggeredSection(
            delay: 250,
            child: _GearSection(event: event),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _StaggeredSection(
          delay: 300,
          child: _DescriptionSection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StaggeredSection(
          delay: 350,
          child: _ParticipantsSection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StaggeredSection(
          delay: 400,
          child: _OrganizerSection(event: event),
        ),
        if (event.hasAfterImages) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          _StaggeredSection(
            delay: 405,
            child: _AfterPhotosGallery(
              event: event,
              onImageTap: onImageTap,
            ),
          ),
        ],
        if (event.status == EcoEventStatus.completed) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          _StaggeredSection(
            delay: 408,
            child: _ImpactSummarySection(
              snapshot: feedbackSnapshot,
              onEdit: onEditFeedback,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _StaggeredSection(
          delay: 410,
          child: _ReminderSection(
            event: event,
            onToggleReminder: onToggleReminder,
          ),
        ),
        if (event.isJoined &&
            !event.isOrganizer &&
            event.status == EcoEventStatus.inProgress) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          _StaggeredSection(
            delay: 415,
            child: _AttendeeCheckInBanner(event: event),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Attendee check-in banner (scan organizer's QR)
// ---------------------------------------------------------------------------

class _AttendeeCheckInBanner extends StatelessWidget {
  const _AttendeeCheckInBanner({required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Scan to check in at event',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
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
            if (!context.mounted || success != true) {
              return;
            }
            AppSnack.show(
              context,
              message: 'Check-in complete.',
              type: AppSnackType.success,
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.qrcode_viewfinder,
                    size: 24,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.isCheckedIn ? 'You are checked in' : 'Event is in progress',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.isCheckedIn
                            ? (event.attendeeCheckedInAt == null
                                ? 'Attendance confirmed'
                                : 'Checked in at '
                                    '${event.attendeeCheckedInAt!.hour.toString().padLeft(2, '0')}:'
                                    '${event.attendeeCheckedInAt!.minute.toString().padLeft(2, '0')}')
                            : (event.canOpenAttendeeCheckIn
                                ? 'Scan the organizer\'s QR to check in'
                                : 'Check-in is temporarily paused'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  event.isCheckedIn
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.chevron_right,
                  size: 18,
                  color: event.isCheckedIn
                      ? AppColors.primaryDark
                      : AppColors.primaryDark.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggeredSection extends StatelessWidget {
  const _StaggeredSection({
    required this.delay,
    required this.child,
  });

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: AppMotion.standard.inMilliseconds + delay),
      curve: AppMotion.emphasized,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Location chip (view site on map)
// ---------------------------------------------------------------------------

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View pollution site, ${event.siteDistanceKm.toStringAsFixed(1)} km away',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.softTransition();
            final PollutionSite site = EventSiteResolver.resolveSiteForEvent(
              event,
            );
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (BuildContext context) =>
                    PollutionSiteDetailScreen(site: site),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  CupertinoIcons.location_fill,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.siteName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· ${event.siteDistanceKm.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.primaryDark.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Title + status pill
// ---------------------------------------------------------------------------

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: event.status.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            event.status.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: event.status.color,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          event.title,
          style: textTheme.titleLarge?.copyWith(
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date & time
// ---------------------------------------------------------------------------

class _DateTimeSection extends StatelessWidget {
  const _DateTimeSection({
    required this.event,
    required this.onExportCalendar,
  });

  final EcoEvent event;
  final VoidCallback onExportCalendar;

  void _showDateInfo(BuildContext context) {
    AppHaptics.tap();
    final Duration diff = event.startDateTime.difference(DateTime.now());
    final String relative;
    if (diff.isNegative) {
      final int daysAgo = diff.inDays.abs();
      relative = daysAgo == 0 ? 'Earlier today' : '$daysAgo day${daysAgo == 1 ? '' : 's'} ago';
    } else if (diff.inDays == 0) {
      relative = 'Today';
    } else if (diff.inDays == 1) {
      relative = 'Tomorrow';
    } else {
      relative = 'In ${diff.inDays} days';
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(CupertinoIcons.calendar, size: 28, color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  event.formattedDate,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.formattedTimeRange}  ·  $relative',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onExportCalendar();
                    },
                    icon: const Icon(CupertinoIcons.calendar_badge_plus, size: 18),
                    label: const Text('Add to calendar'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '${event.formattedDate}, ${event.formattedTimeRange}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDateInfo(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.calendar, size: 22, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.formattedDate,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.formattedTimeRange,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category
// ---------------------------------------------------------------------------

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.event});

  final EcoEvent event;

  void _showCategoryInfo(BuildContext context) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(event.category.icon, size: 28, color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  event.category.label,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  event.category.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Event category: ${event.category.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCategoryInfo(context),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: <Widget>[
                Icon(event.category.icon, size: 20, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.category.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                Icon(
                  CupertinoIcons.info_circle,
                  size: 16,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Details grid (scale + difficulty)
// ---------------------------------------------------------------------------

class _EventDetailsGrid extends StatelessWidget {
  const _EventDetailsGrid({required this.event});

  final EcoEvent event;

  static void _showInfoSheet(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 26, color: color),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasScale = event.scale != null;
    final bool hasDifficulty = event.difficulty != null;

    if (!hasScale && !hasDifficulty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: <Widget>[
        if (hasScale)
          Expanded(
            child: _DetailChip(
              icon: Icons.groups_rounded,
              label: event.scale!.label,
              color: AppColors.primaryDark,
              onTap: () => _showInfoSheet(
                context,
                icon: Icons.groups_rounded,
                title: event.scale!.label,
                description: event.scale!.description,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        if (hasScale && hasDifficulty)
          const SizedBox(width: AppSpacing.sm),
        if (hasDifficulty)
          Expanded(
            child: _DetailChip(
              icon: CupertinoIcons.shield_fill,
              label: event.difficulty!.label,
              color: event.difficulty!.color,
              onTap: () => _showInfoSheet(
                context,
                icon: CupertinoIcons.shield_fill,
                title: event.difficulty!.label,
                description: event.difficulty!.description,
                color: event.difficulty!.color,
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gear section
// ---------------------------------------------------------------------------

class _GearSection extends StatelessWidget {
  const _GearSection({required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Gear to bring',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: event.gear.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              final EventGear gear = event.gear[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(gear.icon, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      gear.label,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Description
// ---------------------------------------------------------------------------

class _DescriptionSection extends StatefulWidget {
  const _DescriptionSection({required this.event});

  final EcoEvent event;

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  static const int _collapsedMaxLines = 4;
  bool _expanded = false;
  bool _needsExpansion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkOverflow();
  }

  void _checkOverflow() {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: widget.event.description,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      maxLines: _collapsedMaxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - AppSpacing.lg * 2);

    final bool overflows = tp.didExceedMaxLines;
    if (overflows != _needsExpansion) {
      setState(() => _needsExpansion = overflows);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'About',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          duration: AppMotion.fast,
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Text(
            widget.event.description,
            maxLines: _collapsedMaxLines,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          secondChild: Text(
            widget.event.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        if (_needsExpansion)
          GestureDetector(
            onTap: () {
              AppHaptics.light();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Participants
// ---------------------------------------------------------------------------

class _ParticipantsSection extends StatelessWidget {
  const _ParticipantsSection({required this.event});

  final EcoEvent event;

  void _showAttendeeList(BuildContext context) {
    AppHaptics.tap();
    final List<_AttendeePreview> attendees = _buildAttendeePreview(event);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return _AttendeeListSheet(
          attendees: attendees,
          joinedCount: event.participantCount,
        );
      },
    );
  }

  static List<_AttendeePreview> _buildAttendeePreview(EcoEvent event) {
    const List<String> pool = <String>[
      'Ana M.', 'Marko T.', 'Jana K.', 'Stefan P.',
      'Elena R.', 'Nikola D.', 'Petra S.', 'Boris V.',
      'Ivana L.', 'Dejan N.', 'Maja G.', 'Filip B.',
    ];
    final List<_AttendeePreview> attendees = <_AttendeePreview>[];
    int slotsLeft = event.participantCount.clamp(0, 1000000);
    int seed = 0;

    void addAttendee({
      required String name,
      required bool isOrganizer,
      required bool isCurrentUser,
    }) {
      if (slotsLeft <= 0) {
        return;
      }
      attendees.add(
        _AttendeePreview(
          name: name,
          isOrganizer: isOrganizer,
          isCurrentUser: isCurrentUser,
          joinedOrder: seed++,
        ),
      );
      slotsLeft -= 1;
    }

    addAttendee(
      name: event.organizerName,
      isOrganizer: true,
      isCurrentUser: event.isOrganizer,
    );
    if (event.isJoined && !event.isOrganizer) {
      addAttendee(name: 'You', isOrganizer: false, isCurrentUser: true);
    }
    for (final String name in pool) {
      if (slotsLeft <= 0) {
        break;
      }
      addAttendee(name: name, isOrganizer: false, isCurrentUser: false);
    }

    int checkedInSlots = event.checkedInCount.clamp(0, attendees.length);
    if (event.isCheckedIn) {
      checkedInSlots = checkedInSlots.clamp(1, attendees.length);
    }
    final List<_AttendeePreview> withStatus = <_AttendeePreview>[];
    for (int i = 0; i < attendees.length; i++) {
      final _AttendeePreview attendee = attendees[i];
      final bool checkedIn = attendee.isCurrentUser
          ? event.isCheckedIn
          : i < checkedInSlots;
      withStatus.add(attendee.copyWith(isCheckedIn: checkedIn));
    }
    return withStatus;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int count = event.participantCount;

    return Semantics(
      button: true,
      label: 'View $count attendees',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: count > 0 ? () => _showAttendeeList(context) : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                _AvatarStack(count: count),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.isJoined && count > 1
                            ? 'You and ${count - 1} other${count == 2 ? '' : 's'} joined'
                            : '$count volunteer${count == 1 ? '' : 's'} joined',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (event.maxParticipants != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${(event.maxParticipants! - count).clamp(0, 1000000)} spots left',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (event.checkedInCount > 0 &&
                          (event.status == EcoEventStatus.inProgress ||
                              event.status == EcoEventStatus.completed))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${event.checkedInCount} of $count checked in',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (count > 0)
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _AttendeeSort {
  recent,
  alphabetical,
  checkedInFirst,
}

class _AttendeePreview {
  const _AttendeePreview({
    required this.name,
    required this.isOrganizer,
    required this.isCurrentUser,
    required this.joinedOrder,
    this.isCheckedIn = false,
  });

  final String name;
  final bool isOrganizer;
  final bool isCurrentUser;
  final int joinedOrder;
  final bool isCheckedIn;

  _AttendeePreview copyWith({
    bool? isCheckedIn,
  }) {
    return _AttendeePreview(
      name: name,
      isOrganizer: isOrganizer,
      isCurrentUser: isCurrentUser,
      joinedOrder: joinedOrder,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    );
  }
}

class _AttendeeListSheet extends StatefulWidget {
  const _AttendeeListSheet({
    required this.attendees,
    required this.joinedCount,
  });

  final List<_AttendeePreview> attendees;
  final int joinedCount;

  @override
  State<_AttendeeListSheet> createState() => _AttendeeListSheetState();
}

class _AttendeeListSheetState extends State<_AttendeeListSheet> {
  final TextEditingController _searchController = TextEditingController();
  _AttendeeSort _sort = _AttendeeSort.recent;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_AttendeePreview> get _visibleAttendees {
    final String query = _query.trim().toLowerCase();
    final List<_AttendeePreview> filtered = widget.attendees.where((a) {
      if (query.isEmpty) {
        return true;
      }
      return a.name.toLowerCase().contains(query);
    }).toList(growable: false);

    filtered.sort((_AttendeePreview a, _AttendeePreview b) {
      switch (_sort) {
        case _AttendeeSort.recent:
          return a.joinedOrder.compareTo(b.joinedOrder);
        case _AttendeeSort.alphabetical:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _AttendeeSort.checkedInFirst:
          if (a.isCheckedIn != b.isCheckedIn) {
            return a.isCheckedIn ? -1 : 1;
          }
          return a.joinedOrder.compareTo(b.joinedOrder);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final List<_AttendeePreview> visible = _visibleAttendees;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Attendees',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    '${widget.joinedCount} joined',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search attendee',
                onChanged: (String value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: CupertinoSlidingSegmentedControl<_AttendeeSort>(
                groupValue: _sort,
                thumbColor: Colors.white,
                backgroundColor: AppColors.inputFill,
                children: const <_AttendeeSort, Widget>{
                  _AttendeeSort.recent: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('Recent'),
                  ),
                  _AttendeeSort.alphabetical: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('A-Z'),
                  ),
                  _AttendeeSort.checkedInFirst: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('Checked-in'),
                  ),
                },
                onValueChanged: (_AttendeeSort? value) {
                  if (value == null) {
                    return;
                  }
                  AppHaptics.light();
                  setState(() {
                    _sort = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        'No attendee matches your search.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      itemCount: visible.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _AttendeeRow(
                          attendee: visible[index],
                          index: index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({
    required this.attendee,
    required this.index,
  });

  final _AttendeePreview attendee;
  final int index;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 6,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.avatarPalette[index % AppColors.avatarPalette.length],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                attendee.name.isNotEmpty ? attendee.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  attendee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (attendee.isOrganizer || attendee.isCurrentUser)
                  Text(
                    attendee.isOrganizer
                        ? (attendee.isCurrentUser ? 'You · Organizer' : 'Organizer')
                        : 'You',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (attendee.isCheckedIn)
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 18,
              color: AppColors.primaryDark,
            ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final int display = count.clamp(0, 4);
    const double size = 32;
    const double overlap = 10;
    final double totalWidth = size + (display - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List<Widget>.generate(display, (int i) {
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.avatarPalette[i % AppColors.avatarPalette.length].withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.panelBackground, width: 2),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + i),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Organizer
// ---------------------------------------------------------------------------

class _OrganizerSection extends StatelessWidget {
  const _OrganizerSection({required this.event});

  final EcoEvent event;

  void _showOrganizerInfo(BuildContext context) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      event.organizerName.isNotEmpty
                          ? event.organizerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  event.organizerName,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  event.isOrganizer ? 'This is your event' : 'Event organizer',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(CupertinoIcons.calendar, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Event created on ${event.createdAt.day}/${event.createdAt.month}/${event.createdAt.year}',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Organizer: ${event.organizerName}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrganizerInfo(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      event.organizerName.isNotEmpty
                          ? event.organizerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Organized by',
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                      ),
                      Text(
                        event.organizerName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// After-photos gallery
// ---------------------------------------------------------------------------

class _AfterPhotosGallery extends StatelessWidget {
  const _AfterPhotosGallery({
    required this.event,
    required this.onImageTap,
  });

  final EcoEvent event;
  final ValueChanged<int> onImageTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'After cleanup',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: event.afterImagePaths.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              final String path = event.afterImagePaths[index];
              final bool isAsset = path.startsWith('assets/');
              final ImageProvider provider =
                  isAsset ? AssetImage(path) : FileImage(File(path)) as ImageProvider;

              return Semantics(
                button: true,
                label: 'View after cleanup photo ${index + 1} of ${event.afterImagePaths.length}',
                child: GestureDetector(
                  onTap: () => onImageTap(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: provider,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.photo,
                            size: 24,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fullscreen gallery page
// ---------------------------------------------------------------------------

class _FullscreenGalleryPage extends StatefulWidget {
  const _FullscreenGalleryPage({
    required this.event,
    required this.initialIndex,
  });

  final EcoEvent event;
  final int initialIndex;

  @override
  State<_FullscreenGalleryPage> createState() => _FullscreenGalleryPageState();
}

class _FullscreenGalleryPageState extends State<_FullscreenGalleryPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.event.afterImagePaths.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (int index) => setState(() => _currentIndex = index),
            itemBuilder: (BuildContext context, int index) {
              final String path = widget.event.afterImagePaths[index];
              final bool isAsset = path.startsWith('assets/');
              final ImageProvider provider =
                  isAsset ? AssetImage(path) : FileImage(File(path)) as ImageProvider;
              return InteractiveViewer(
                child: Center(
                  child: Image(
                    image: provider,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
                      return const Icon(
                        CupertinoIcons.photo,
                        size: 48,
                        color: Colors.white54,
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () {
                      AppHaptics.tap();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    color: Colors.white,
                    iconSize: 28,
                  ),
                  const Spacer(),
                  if (total > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reminder and trust
// ---------------------------------------------------------------------------

class _ImpactSummarySection extends StatelessWidget {
  const _ImpactSummarySection({
    required this.snapshot,
    required this.onEdit,
  });

  final EventFeedbackSnapshot? snapshot;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final EventFeedbackSnapshot? data = snapshot;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Impact summary',
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              CupertinoButton(
                onPressed: onEdit,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                minimumSize: Size.zero,
                child: Text(data == null ? 'Add' : 'Edit'),
              ),
            ],
          ),
          if (data == null) ...<Widget>[
            Text(
              'Capture cleanup outcomes, effort, and lessons learned.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ] else ...<Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                _ImpactBadge(label: '${data.rating}★ rating'),
                _ImpactBadge(label: '${data.bagsCollected} bags'),
                _ImpactBadge(label: '${data.volunteerHours.toStringAsFixed(1)}h'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${data.estimatedKg.toStringAsFixed(1)} kg removed · '
              '${data.estimatedCo2SavedKg.toStringAsFixed(1)} kg CO2e avoided',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (data.notes.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                data.notes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.event,
    required this.onToggleReminder,
  });

  final EcoEvent event;
  final VoidCallback onToggleReminder;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.bell_fill,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Event reminder',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.reminderEnabled
                      ? (event.reminderAt == null
                          ? 'Reminder is on'
                          : 'Set for ${event.reminderAt!.hour.toString().padLeft(2, '0')}:${event.reminderAt!.minute.toString().padLeft(2, '0')}')
                      : 'Get notified before event starts',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: onToggleReminder,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            child: Text(
              event.reminderEnabled ? 'Disable' : 'Enable',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky bottom CTA
// ---------------------------------------------------------------------------

class _StickyBottomCTA extends StatelessWidget {
  const _StickyBottomCTA({
    required this.event,
    required this.onToggleJoin,
    required this.onToggleReminder,
    required this.onStartEvent,
    required this.onManageCheckIn,
    required this.onOpenAttendeeCheckIn,
    required this.onOpenCleanupEvidence,
  });

  final EcoEvent event;
  final VoidCallback onToggleJoin;
  final VoidCallback onToggleReminder;
  final VoidCallback onStartEvent;
  final VoidCallback onManageCheckIn;
  final VoidCallback onOpenAttendeeCheckIn;
  final VoidCallback onOpenCleanupEvidence;

  @override
  Widget build(BuildContext context) {
    final double bottomSafe = MediaQuery.of(context).padding.bottom;

    final String label;
    final bool enabled;
    final VoidCallback? onPressed;
    String? secondaryLabel;
    VoidCallback? onSecondaryPressed;

    if (event.isOrganizer) {
      if (event.status == EcoEventStatus.upcoming) {
        label = 'Start event';
        enabled = true;
        onPressed = onStartEvent;
      } else if (event.status == EcoEventStatus.inProgress) {
        label = 'Manage check-in';
        enabled = true;
        onPressed = onManageCheckIn;
      } else if (event.status == EcoEventStatus.completed) {
        label = event.hasAfterImages ? 'Edit after photos' : 'Upload after photos';
        enabled = true;
        onPressed = onOpenCleanupEvidence;
      } else {
        label = event.status.label;
        enabled = false;
        onPressed = null;
      }
    } else if (event.status == EcoEventStatus.inProgress && event.isJoined) {
      if (event.isCheckedIn) {
        label = 'Checked in';
        enabled = false;
        onPressed = null;
      } else if (event.canOpenAttendeeCheckIn) {
        label = 'Scan to check in';
        enabled = true;
        onPressed = onOpenAttendeeCheckIn;
      } else {
        label = 'Check-in paused';
        enabled = false;
        onPressed = null;
      }
    } else if (event.isJoined) {
      label = event.reminderEnabled ? 'Turn reminder off' : 'Set reminder';
      enabled = true;
      onPressed = onToggleReminder;
      secondaryLabel = 'Leave event';
      onSecondaryPressed = onToggleJoin;
    } else if (!event.isJoinable) {
      label = event.status.label;
      enabled = false;
      onPressed = null;
    } else {
      label = 'Join eco action';
      enabled = true;
      onPressed = onToggleJoin;
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + bottomSafe,
        ),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: secondaryLabel == null
            ? PrimaryButton(
                label: label,
                enabled: enabled,
                onPressed: enabled ? (onPressed ?? onToggleJoin) : null,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  PrimaryButton(
                    label: label,
                    enabled: enabled,
                    onPressed: enabled ? onPressed : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: onSecondaryPressed,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        secondaryLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

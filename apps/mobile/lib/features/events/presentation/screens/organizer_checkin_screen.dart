import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/check_in_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/organizer_checkin/organizer_checkin_widgets.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Organizer check-in screen: displays a QR code attendees scan.
/// After each scan the QR regenerates. Checked-in names appear in the list.
class OrganizerCheckInScreen extends StatefulWidget {
  const OrganizerCheckInScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<OrganizerCheckInScreen> createState() => _OrganizerCheckInScreenState();
}

class _OrganizerCheckInScreenState extends State<OrganizerCheckInScreen> {
  final EventsRepository _eventsRepository = EventsRepositoryRegistry.instance;
  final CheckInRepository _checkInRepository = CheckInRepositoryRegistry.instance;
  final Random _rnd = Random();
  final TextEditingController _manualNameController = TextEditingController();
  CheckInQrPayload? _payload;
  Timer? _refreshTicker;

  EcoEvent? get _eventOrNull => _eventsRepository.findById(widget.eventId);

  EcoEvent get _event => _eventOrNull!;

  List<CheckedInAttendee> get _attendees =>
      _checkInRepository.checkedInAttendees(_event.id);

  int get _remainingPayloadMs {
    final CheckInQrPayload? payload = _payload;
    if (payload == null) {
      return 0;
    }
    final int elapsed =
        DateTime.now().millisecondsSinceEpoch - payload.issuedAtMs;
    return (_checkInRepository.payloadTtl.inMilliseconds - elapsed).clamp(
      0,
      _checkInRepository.payloadTtl.inMilliseconds,
    );
  }

  int get _remainingPayloadSeconds => (_remainingPayloadMs / 1000).ceil();

  void _issueNewPayload() {
    if (!_checkInRepository.isOpen(_event.id)) {
      setState(() => _payload = null);
      return;
    }
    final CheckInQrPayload next = _checkInRepository.issuePayload(eventId: _event.id);
    _eventsRepository.rotateCheckInSession(
      eventId: _event.id,
      sessionId: next.sessionId,
    );
    setState(() => _payload = next);
  }

  void _startRefreshTicker() {
    _refreshTicker?.cancel();
    _refreshTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (!_event.isCheckInOpen) {
        if (_payload != null) {
          setState(() => _payload = null);
        }
        return;
      }
      if (_payload == null || _remainingPayloadMs <= 0) {
        _issueNewPayload();
        return;
      }
      setState(() {});
    });
  }

  void _ensureSession() {
    final String sessionId = _checkInRepository.ensureSession(event: _event);
    _eventsRepository.rotateCheckInSession(
      eventId: _event.id,
      sessionId: sessionId,
    );
    _issueNewPayload();
  }

  void _simulateCheckIn() {
    AppHaptics.tap();
    if (_payload == null) {
      _issueNewPayload();
      return;
    }
    const List<String> mockNames = <String>[
      'Ana M.',
      'Marko S.',
      'Elena K.',
      'Stefan D.',
      'Marija P.',
      'Nikola C.',
      'Sara V.',
    ];
    final List<String> available = mockNames.where((String name) {
      final String id = 'att_${name.toLowerCase().replaceAll(' ', '_')}';
      return !_attendees.any((CheckedInAttendee a) => a.id == id);
    }).toList(growable: false);
    if (available.isEmpty) {
      AppSnack.show(
        context,
        message: 'All mock attendees are already checked in.',
        type: AppSnackType.warning,
      );
      return;
    }

    final String name = available[_rnd.nextInt(available.length)];
    final String attendeeId = 'att_${name.toLowerCase().replaceAll(' ', '_')}';
    final CheckInSubmissionResult result = _checkInRepository.submitScan(
      rawPayload: _payload!.encode(),
      expectedEventId: _event.id,
      attendeeId: attendeeId,
      attendeeName: name,
    );
    _showSubmissionFeedback(result, name);
    if (result.isSuccess) {
      _issueNewPayload();
    }
  }

  Future<void> _addManualAttendee() async {
    _manualNameController.clear();
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Manual check-in'),
          content: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: CupertinoTextField(
              controller: _manualNameController,
              placeholder: 'Attendee name',
              autofocus: true,
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (confirmed != true) {
      return;
    }
    final String name = _manualNameController.text.trim();
    if (name.isEmpty) {
      AppSnack.show(
        context,
        message: 'Enter attendee name first.',
        type: AppSnackType.warning,
      );
      return;
    }
    final String attendeeId = 'manual_${name.toLowerCase().replaceAll(' ', '_')}';
    final bool added = _checkInRepository.markAttendeeCheckedIn(
      eventId: _event.id,
      attendeeId: attendeeId,
      attendeeName: name,
    );
    if (!added) {
      AppSnack.show(
        context,
        message: '$name is already checked in.',
        type: AppSnackType.warning,
      );
      return;
    }
    AppSnack.show(
      context,
      message: '$name added by organizer.',
      type: AppSnackType.success,
    );
    _issueNewPayload();
  }

  void _removeAttendee(CheckedInAttendee attendee) {
    final bool removed = _checkInRepository.removeCheckedInAttendee(
      eventId: _event.id,
      attendeeId: attendee.id,
    );
    if (!removed) {
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: 'Could not remove ${attendee.name}.',
        type: AppSnackType.warning,
      );
      return;
    }
    AppSnack.show(
      context,
      message: '${attendee.name} removed from check-in.',
      type: AppSnackType.warning,
    );
  }

  Future<void> _handleEndEvent() async {
    AppHaptics.tap();
    _checkInRepository.closeSession(_event.id);
    final bool changed = _eventsRepository.updateStatus(
      _event.id,
      EcoEventStatus.completed,
    );
    if (!changed) {
      AppHaptics.warning();
      AppSnack.show(context, message: 'Unable to complete the event.', type: AppSnackType.warning);
      return;
    }
    final int count = _attendees.length;
    if (!mounted) return;
    await _showEndSummary(count);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _showEndSummary(int attendeeCount) async {
    AppHaptics.success();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: AppSpacing.sheetHandleHeight,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 36,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Event ended',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    attendeeCount == 0
                        ? 'Thanks for organizing!'
                        : '$attendeeCount attendee${attendeeCount == 1 ? '' : 's'} checked in.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Upload after photos from the event detail.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Done',
                      enabled: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePauseResume() {
    AppHaptics.tap();
    final bool isOpen = _event.isCheckInOpen;
    final bool changed = isOpen
        ? _checkInRepository.pauseSession(_event.id)
        : _checkInRepository.resumeSession(_event.id);
    if (!changed) {
      AppHaptics.warning();
      return;
    }
    if (!isOpen) {
      _issueNewPayload();
    }
    AppSnack.show(
      context,
      message: isOpen ? 'Check-in paused.' : 'Check-in resumed.',
      type: AppSnackType.success,
    );
  }

  void _handleCancelEvent() {
    AppHaptics.warning();
    _checkInRepository.closeSession(_event.id);
    final bool changed = _eventsRepository.updateStatus(
      _event.id,
      EcoEventStatus.cancelled,
    );
    if (!changed) {
      AppSnack.show(context, message: 'Unable to cancel the event.', type: AppSnackType.warning);
      return;
    }
    AppSnack.show(
      context,
      message: 'Event cancelled.',
      type: AppSnackType.warning,
    );
    Navigator.of(context).pop();
  }

  void _showSubmissionFeedback(CheckInSubmissionResult result, String name) {
    final String message = switch (result.status) {
      CheckInSubmissionStatus.success => '$name checked in',
      CheckInSubmissionStatus.invalidFormat => 'Invalid QR code.',
      CheckInSubmissionStatus.wrongEvent => 'Wrong event QR.',
      CheckInSubmissionStatus.sessionClosed => 'Check-in is currently paused.',
      CheckInSubmissionStatus.sessionExpired => 'QR expired. Generate a new one.',
      CheckInSubmissionStatus.replayDetected => 'QR already used. Regenerating...',
      CheckInSubmissionStatus.alreadyCheckedIn => '$name is already checked in.',
    };
    if (result.isSuccess) {
      AppHaptics.success();
    }
    AppSnack.show(
      context,
      message: message,
      type: result.isSuccess ? AppSnackType.success : AppSnackType.warning,
    );
  }

  void _onRepoChanged() {
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

  @override
  void initState() {
    super.initState();
    _eventsRepository.loadInitialIfNeeded();
    _eventsRepository.addListener(_onRepoChanged);
    _checkInRepository.addListener(_onRepoChanged);
    if (_eventOrNull != null) {
      _ensureSession();
    }
    _startRefreshTicker();
  }

  @override
  void dispose() {
    _eventsRepository.removeListener(_onRepoChanged);
    _checkInRepository.removeListener(_onRepoChanged);
    _refreshTicker?.cancel();
    _manualNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EcoEvent? event = _eventOrNull;
    if (event == null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
          title: const Text('Check-in'),
        ),
        body: const Center(
          child: Text('This event is no longer available.'),
        ),
      );
    }
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isOpen = event.isCheckInOpen;
    final List<CheckedInAttendee> attendees = _attendees;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        leading: const AppBackButton(),
        title: Text(
          'Check-in',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radius18),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            event.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Attendees should always scan the newest QR. The code refreshes automatically before it expires.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Hold your phone so attendees can scan',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PulsingQRContainer(
                      isActive: isOpen && _payload != null,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                        duration: AppMotion.standard,
                        switchInCurve: AppMotion.emphasized,
                        switchOutCurve: AppMotion.emphasized,
                        child: isOpen && _payload != null
                            ? TweenAnimationBuilder<double>(
                                key: ValueKey<String>(_payload!.nonce),
                                tween: Tween<double>(begin: 0.92, end: 1),
                                duration: AppMotion.standard,
                                curve: AppMotion.emphasized,
                                builder: (BuildContext context, double value, Widget? child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: QrImageView(
                                  key: ValueKey<String>(_payload!.nonce),
                                  data: _payload!.encode(),
                                  version: QrVersions.auto,
                                  size: 220,
                                  backgroundColor: AppColors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: AppColors.textPrimary,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              )
                            : SizedBox(
                              width: 220,
                              height: 220,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    CupertinoIcons.pause_circle_fill,
                                    size: 42,
                                    color: AppColors.textMuted.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Check-in paused',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        StatusPill(
                          label: isOpen ? 'Open' : 'Paused',
                          color: isOpen ? AppColors.primaryDark : AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (isOpen && _payload != null) ...<Widget>[
                          StatusPill(
                            label: 'Refresh in ${_remainingPayloadSeconds}s',
                            color: _remainingPayloadSeconds <= 10
                                ? AppColors.accentDanger
                                : AppColors.textPrimary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            isOpen
                                ? 'QR refreshes automatically and after each scan'
                                : 'Resume check-in to issue a fresh QR',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(
                      label: 'Manual override: mark attendee present',
                      button: true,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _addManualAttendee,
                        child: Text(
                          'Manual override: mark attendee present',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Checked in',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        '${attendees.length}',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (attendees.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.person_2,
                          size: 48,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No one checked in yet',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Attendees scan your QR to check in',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final CheckedInAttendee attendee = attendees[index];
                      return CheckedInRow(
                        attendee: attendee,
                        onRemove: () => _removeAttendee(attendee),
                        avatarIndex: index,
                      );
                    },
                    childCount: attendees.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg + bottomSafe,
                ),
                child: Column(
                  children: <Widget>[
                    PrimaryButton(
                      label: 'End event',
                      enabled: true,
                      onPressed: _handleEndEvent,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _handlePauseResume,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                        ),
                        child: Text(
                          isOpen ? 'Pause check-in' : 'Resume check-in',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CupertinoButton(
                      onPressed: _handleCancelEvent,
                      child: Text(
                        'Cancel event',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.accentDanger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (kDebugMode) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      CupertinoButton(
                        onPressed: _simulateCheckIn,
                        child: Text(
                          'Simulate check-in (dev)',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/l10n/duplicate_event_conflict.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_schedule_conflict_preview.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_schedule_constraints.dart';
import 'package:chisto_mobile/features/events/presentation/utils/extend_event_end_policy.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/edit_event/edit_event_schedule_conflict_callout.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:intl/intl.dart' hide TextDirection;

Future<void> showExtendEventEndSheet({
  required BuildContext context,
  required EcoEvent event,
  required EventsRepository eventsRepository,
}) {
  return showEventsSurfaceModal<void>(
    context: context,
    builder: (BuildContext ctx) => ExtendEventEndSheet(
      event: event,
      eventsRepository: eventsRepository,
    ),
  );
}

class ExtendEventEndSheet extends StatefulWidget {
  const ExtendEventEndSheet({
    super.key,
    required this.event,
    required this.eventsRepository,
  });

  final EcoEvent event;
  final EventsRepository eventsRepository;

  @override
  State<ExtendEventEndSheet> createState() => _ExtendEventEndSheetState();
}

class _ExtendEventEndSheetState extends State<ExtendEventEndSheet> {
  late DateTime _proposedEndLocal;
  Timer? _scheduleConflictTimer;
  ConflictingEventInfo? _scheduleConflictHint;
  int _scheduleConflictRequestId = 0;
  bool _schedulePreviewFailed = false;
  bool _submitting = false;

  EcoEvent get _event => widget.event;

  @override
  void initState() {
    super.initState();
    _proposedEndLocal = clampProposedEndLocal(
      event: _event,
      candidate: _event.endDateTime,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scheduleConflictPreviewDebounced();
      }
    });
  }

  @override
  void dispose() {
    _scheduleConflictTimer?.cancel();
    super.dispose();
  }

  String _formatConflictWhen(BuildContext context, DateTime at) {
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_jm().format(at.toLocal());
  }

  Future<void> _showDuplicateSubmitDialog(AppError error) async {
    final DuplicateEventConflictUi? dup =
        duplicateEventConflictUiFromAppError(error);
    if (!mounted) {
      return;
    }
    if (dup == null) {
      AppSnack.show(
        context,
        message: localizedAppErrorMessage(context.l10n, error),
        type: AppSnackType.warning,
      );
      return;
    }
    final String when = _formatConflictWhen(context, dup.scheduledAt);
    if (!mounted) {
      return;
    }
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(ctx.l10n.editEventDuplicateSubmitTitle),
        content: Text(ctx.l10n.editEventDuplicateSubmitBody(dup.title, when)),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonGotIt),
          ),
        ],
      ),
    );
  }

  void _scheduleConflictPreviewDebounced() {
    _scheduleConflictTimer?.cancel();
    final ScheduleValidationIssue? issue = validateInProgressEditSchedule(
      dateOnly: DateUtils.dateOnly(_event.date),
      start: _event.startTime,
      end: eventTimeFromDateTime(_proposedEndLocal),
      now: DateTime.now(),
    );
    if (issue != null) {
      if (_scheduleConflictHint != null || _schedulePreviewFailed) {
        setState(() {
          _scheduleConflictHint = null;
          _schedulePreviewFailed = false;
        });
      }
      return;
    }
    _scheduleConflictTimer = Timer(const Duration(milliseconds: 480), () {
      if (!mounted) {
        return;
      }
      final int token = ++_scheduleConflictRequestId;
      final DateTime startLocal = _event.startDateTime;
      final DateTime endLocal = _proposedEndLocal;
      unawaited(() async {
        try {
          final EventScheduleConflictPreview preview =
              await widget.eventsRepository.checkScheduleConflict(
            siteId: _event.siteId,
            scheduledAt: startLocal.toUtc(),
            endAt: endLocal.toUtc(),
            excludeEventId: _event.id,
          );
          if (!mounted || token != _scheduleConflictRequestId) {
            return;
          }
          setState(() {
            _scheduleConflictHint = preview.hasConflict
                ? preview.conflictingEvent
                : null;
            _schedulePreviewFailed = false;
          });
        } on Object {
          if (!mounted || token != _scheduleConflictRequestId) {
            return;
          }
          setState(() {
            _scheduleConflictHint = null;
            _schedulePreviewFailed = true;
          });
        }
      }());
    });
  }

  void _bumpEnd(Duration delta) {
    AppHaptics.tap();
    setState(() {
      _proposedEndLocal = clampProposedEndLocal(
        event: _event,
        candidate: _proposedEndLocal.add(delta),
      );
    });
    _scheduleConflictPreviewDebounced();
  }

  Future<void> _pickCustomEndTime() async {
    AppHaptics.tap();
    final TimeOfDay initial = TimeOfDay.fromDateTime(_proposedEndLocal);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) {
      return;
    }
    final DateTime d = _event.date;
    final DateTime candidate = DateTime(
      d.year,
      d.month,
      d.day,
      picked.hour,
      picked.minute,
    );
    setState(() {
      _proposedEndLocal = clampProposedEndLocal(
        event: _event,
        candidate: candidate,
      );
    });
    _scheduleConflictPreviewDebounced();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final ScheduleValidationIssue? issue = validateInProgressEditSchedule(
      dateOnly: DateUtils.dateOnly(_event.date),
      start: _event.startTime,
      end: eventTimeFromDateTime(_proposedEndLocal),
      now: DateTime.now(),
    );
    if (issue != null) {
      AppHaptics.warning();
      final String message = switch (issue) {
        ScheduleValidationIssue.endNotAfterStart =>
          context.l10n.eventsExtendEndInvalidRange,
        ScheduleValidationIssue.endAfterLocalDayEnd =>
          context.l10n.eventsExtendEndInvalidRange,
        ScheduleValidationIssue.startTooSoon =>
          context.l10n.eventsExtendEndInvalidRange,
        ScheduleValidationIssue.endTooSoon => context.l10n.eventsExtendEndTooSoon,
      };
      AppSnack.show(
        context,
        message: message,
        type: AppSnackType.warning,
      );
      return;
    }

    final List<ConnectivityResult> connectivity =
        await ConnectivityGate.check();
    if (!mounted) {
      return;
    }
    final bool online = ConnectivityGate.isOnline(connectivity);
    if (!online) {
      AppSnack.show(
        context,
        message: context.l10n.editEventOfflineSave,
        type: AppSnackType.warning,
      );
      return;
    }

    if (_scheduleConflictHint != null) {
      final ConflictingEventInfo hint = _scheduleConflictHint!;
      if (!mounted) {
        return;
      }
      final bool? goAhead = await showCupertinoDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => CupertinoAlertDialog(
          title: Text(ctx.l10n.eventsScheduleConflictPreviewTitle),
          content: Text(
            ctx.l10n.eventsScheduleConflictPreviewBody(
              hint.title,
              _formatConflictWhen(ctx, hint.scheduledAt),
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.eventsScheduleConflictAdjustTime),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.l10n.eventsScheduleConflictContinue),
            ),
          ],
        ),
      );
      if (goAhead != true || !mounted) {
        return;
      }
    }

    final DateTime newEndUtc = _proposedEndLocal.toUtc();
    if (newEndUtc.millisecondsSinceEpoch ==
        _event.endDateTime.toUtc().millisecondsSinceEpoch) {
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsExtendEndSameAsCurrent,
        type: AppSnackType.warning,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.eventsRepository.updateEventDetails(
        _event.id,
        EventUpdatePayload(endAtUtc: newEndUtc),
      );
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      if (e.code == 'DUPLICATE_EVENT') {
        await _showDuplicateSubmitDialog(e);
      } else {
        AppSnack.show(
          context,
          message: localizedAppErrorMessage(context.l10n, e),
          type: AppSnackType.warning,
        );
      }
      return;
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      AppSnack.show(
        context,
        message: context.l10n.eventsMutationFailedGeneric,
        type: AppSnackType.warning,
      );
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    AppHaptics.success();
    AppSnack.show(
      context,
      message: context.l10n.eventsExtendEndSuccess,
      type: AppSnackType.success,
    );
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ReportSheetScaffold(
      title: context.l10n.eventsExtendEndSheetTitle,
      subtitle: context.l10n.eventsExtendEndSheetSubtitle(
        MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(_event.endDateTime),
        ),
      ),
      fitToContent: true,
      footer: PrimaryButton(
        label: context.l10n.eventsExtendEndApply,
        enabled: !_submitting,
        isLoading: _submitting,
        onPressed: _submitting ? null : () => unawaited(_submit()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.l10n.eventsExtendEndCurrentChoice(
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(_proposedEndLocal),
              ),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              ActionChip(
                label: Text(context.l10n.eventsExtendEndPlus15),
                onPressed: _submitting ? null : () => _bumpEnd(const Duration(minutes: 15)),
              ),
              ActionChip(
                label: Text(context.l10n.eventsExtendEndPlus30),
                onPressed: _submitting ? null : () => _bumpEnd(const Duration(minutes: 30)),
              ),
              ActionChip(
                label: Text(context.l10n.eventsExtendEndPlus60),
                onPressed: _submitting ? null : () => _bumpEnd(const Duration(hours: 1)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _submitting ? null : () => unawaited(_pickCustomEndTime()),
              child: Text(context.l10n.eventsExtendEndCustomTime),
            ),
          ),
          if (_scheduleConflictHint != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            EditEventScheduleConflictCallout(
              bodyText: context.l10n.eventsScheduleConflictPreviewBody(
                _scheduleConflictHint!.title,
                _formatConflictWhen(context, _scheduleConflictHint!.scheduledAt),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:feature_events/src/application/schedule_conflict_use_case.dart';
import 'package:feature_events/src/domain/models/event_schedule_conflict_preview.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:flutter/cupertino.dart';

/// Debounced schedule overlap preview shared by create/edit event sheets.
class ScheduleConflictPreviewController {
  ScheduleConflictPreviewController({
    required this.eventsRepository,
    required this.isMounted,
    required this.onChanged,
  });

  final EventsRepository eventsRepository;
  final bool Function() isMounted;
  final VoidCallback onChanged;

  static const Duration debounceDelay = Duration(milliseconds: 480);

  final ScheduleConflictUseCase _useCase = const ScheduleConflictUseCase();

  Timer? _timer;
  ConflictingEventInfo? hint;
  bool previewFailed = false;
  int _requestId = 0;

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  String formatConflictWhen(BuildContext context, DateTime at) {
    return _useCase.formatConflictWhen(context, at);
  }

  void schedulePreview({
    required bool scheduleValid,
    required String siteId,
    required DateTime startLocal,
    required DateTime endLocal,
    String? excludeEventId,
    bool clearOnInvalid = true,
  }) {
    _timer?.cancel();
    if (!scheduleValid) {
      if (clearOnInvalid && (hint != null || previewFailed)) {
        hint = null;
        previewFailed = false;
        onChanged();
      } else if (clearOnInvalid && hint != null) {
        hint = null;
        onChanged();
      }
      return;
    }
    _timer = Timer(debounceDelay, () {
      if (!isMounted()) {
        return;
      }
      final int token = ++_requestId;
      unawaited(() async {
        try {
          final EventScheduleConflictPreview preview = await _useCase
              .checkConflict(
                repository: eventsRepository,
                siteId: siteId,
                startLocal: startLocal,
                endLocal: endLocal,
                excludeEventId: excludeEventId,
              );
          if (!isMounted() || token != _requestId) {
            return;
          }
          hint = preview.hasConflict ? preview.conflictingEvent : null;
          previewFailed = false;
          onChanged();
        } on Object {
          if (!isMounted() || token != _requestId) {
            return;
          }
          hint = null;
          previewFailed = excludeEventId != null;
          onChanged();
        }
      }());
    });
  }

  Future<bool?> confirmProceedDespiteConflict(BuildContext context) async {
    final ConflictingEventInfo? conflict = hint;
    if (conflict == null) {
      return true;
    }
    return showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(ctx.l10n.eventsScheduleConflictPreviewTitle),
        content: Text(
          ctx.l10n.eventsScheduleConflictPreviewBody(
            conflict.title,
            formatConflictWhen(ctx, conflict.scheduledAt),
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
  }
}

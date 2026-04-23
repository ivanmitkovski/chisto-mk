import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/l10n/duplicate_event_conflict.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_schedule_conflict_preview.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/edit_event_form_state.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_schedule_constraints.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/edit_event/edit_event_form_primitives.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/edit_event/edit_event_help_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/edit_event/edit_event_schedule_conflict_callout.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_calendar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_form_picker_tile.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/time_range_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Organizer-only editor for fields supported by `PATCH /events/:id`.
class EditEventSheet extends StatefulWidget {
  const EditEventSheet({super.key, required this.event});

  final EcoEvent event;

  @override
  State<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<EditEventSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxParticipantsController;
  late final EditEventFormSnapshot _initialSnapshot;
  late DateTime _selectedDate;
  late EventTime _startTime;
  late EventTime _endTime;
  late EcoEventCategory _category;
  late Set<EventGear> _gear;
  late CleanupScale _scale;
  late EventDifficulty _difficulty;
  bool _submitting = false;
  bool _showValidationErrors = false;
  bool _networkOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _netSub;
  Timer? _scheduleConflictTimer;
  ConflictingEventInfo? _scheduleConflictHint;
  int _scheduleConflictRequestId = 0;
  bool _schedulePreviewFailed = false;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _maxParticipantsFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  EcoEvent get _event => widget.event;

  bool get _isTimeValid {
    if (_event.status == EcoEventStatus.inProgress) {
      return EcoEvent.isValidRange(_startTime, _endTime);
    }
    final DateTime si = eventScheduleInstantLocal(
      DateUtils.dateOnly(_selectedDate),
      _startTime,
    );
    final DateTime ei = eventScheduleInstantLocal(
      DateUtils.dateOnly(_selectedDate),
      _endTime,
    );
    return ei.isAfter(si);
  }

  ScheduleValidationIssue? _editScheduleIssue() {
    return validateEditSchedule(
      status: _event.status,
      dateOnly: DateUtils.dateOnly(_selectedDate),
      start: _startTime,
      end: _endTime,
      now: DateTime.now(),
    );
  }

  bool get _isScheduleValid => _editScheduleIssue() == null;

  ({DateTime? minStart, DateTime? minEnd}) _editPickerBounds() {
    final DateTime dateOnly = DateUtils.dateOnly(_selectedDate);
    final DateTime now = DateTime.now();
    final DateTime? minStart = _event.status == EcoEventStatus.upcoming
        ? pickerMinimumForStart(dateOnly: dateOnly, now: now)
        : null;
    final DateTime minEnd = pickerMinimumForEnd(
      dateOnly: dateOnly,
      start: _startTime,
      now: now,
      editStatus: _event.status == EcoEventStatus.upcoming
          ? null
          : _event.status,
    );
    return (minStart: minStart, minEnd: minEnd);
  }

  bool get _isDirty {
    final int? maxParsed = editEventParsedMaxParticipants(
      _maxParticipantsController.text.trim(),
    );
    return !_initialSnapshot.matches(
      titleTrimmed: _titleController.text.trim(),
      descriptionTrimmed: _descriptionController.text.trim(),
      maxParticipants: maxParsed,
      dateOnly: DateUtils.dateOnly(_selectedDate),
      endDateOnly: DateUtils.dateOnly(_selectedDate),
      startTime: _startTime,
      endTime: _endTime,
      category: _category,
      gear: _gear,
      scale: _scale,
      difficulty: _difficulty,
    );
  }

  bool get _isValid {
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String maxField = _maxParticipantsController.text.trim();
    return editEventTitleIssueKey(title) == null &&
        editEventDescriptionIssueKey(description) == null &&
        editEventMaxParticipantsIssueKey(maxField) == null &&
        _isTimeValid &&
        _isScheduleValid;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _event.title);
    _descriptionController = TextEditingController(text: _event.description);
    _maxParticipantsController = TextEditingController(
      text: _event.maxParticipants?.toString() ?? '',
    );
    _selectedDate = _event.date;
    _startTime = _event.startTime;
    _endTime = _event.spansMultipleCalendarDays
        ? const EventTime(hour: 23, minute: 59)
        : _event.endTime;
    _category = _event.category;
    _gear = _event.gear.toSet();
    _scale = _event.scale ?? CleanupScale.small;
    _difficulty = _event.difficulty ?? EventDifficulty.easy;
    _initialSnapshot = EditEventFormSnapshot.fromEvent(_event);

    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.smooth,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final bool reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
      _scheduleConflictPreviewDebounced();
    });

    unawaited(ConnectivityGate.check().then((List<ConnectivityResult> r) {
      if (!mounted) {
        return;
      }
      setState(() => _networkOnline = ConnectivityGate.isOnline(r));
    }));
    _netSub = ConnectivityGate.watch().listen((List<ConnectivityResult> r) {
      if (!mounted) {
        return;
      }
      setState(() => _networkOnline = ConnectivityGate.isOnline(r));
    });
  }

  @override
  void dispose() {
    _netSub?.cancel();
    _scheduleConflictTimer?.cancel();
    _entranceController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _maxParticipantsFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatConflictWhen(BuildContext context, DateTime at) {
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_jm().format(at.toLocal());
  }

  void _scheduleConflictPreviewDebounced() {
    _scheduleConflictTimer?.cancel();
    if (!_isScheduleValid) {
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
      final DateTime startLocal = eventScheduleInstantLocal(
        DateUtils.dateOnly(_selectedDate),
        _startTime,
      );
      final DateTime endLocal = eventScheduleInstantLocal(
        DateUtils.dateOnly(_selectedDate),
        _endTime,
      );
      unawaited(() async {
        try {
          final EventScheduleConflictPreview preview =
              await EventsRepositoryRegistry.instance.checkScheduleConflict(
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

  Future<void> _requestClose() async {
    if (!_isDirty) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      return;
    }
    final bool? discard = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(ctx.l10n.editEventDiscardTitle),
        content: Text(ctx.l10n.editEventDiscardMessage),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.editEventDiscardKeepEditing),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.editEventDiscardConfirm),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showCategoryPicker() {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.createEventCategoryTitle,
          subtitle: ctx.l10n.createEventCategorySubtitle,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: ctx.l10n.commonClose,
            onTap: () => Navigator.of(ctx).pop(),
          ),
          maxHeightFactor: 0.82,
          addBottomInset: false,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
              ...EcoEventCategory.values.expand((EcoEventCategory cat) {
                final bool isActive = cat == _category;
                return <Widget>[
                  ReportActionTile(
                    icon: cat.icon,
                    title: cat.localizedLabel(ctx.l10n),
                    subtitle: cat.localizedDescription(ctx.l10n),
                    tone: isActive
                        ? ReportSurfaceTone.accent
                        : ReportSurfaceTone.neutral,
                    trailing: Icon(
                      isActive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 22,
                      color: isActive
                          ? AppColors.primaryDark
                          : AppColors.divider,
                    ),
                    onTap: () {
                      AppHaptics.tap();
                      setState(() => _category = cat);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  if (cat != EcoEventCategory.values.last)
                    const SizedBox(height: AppSpacing.sm),
                ];
              }),
            ],
          ),
        );
      },
    );
  }

  void _showScalePicker() {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.createEventTeamSizeTitle,
          subtitle: ctx.l10n.createEventTeamSizeSubtitle,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: ctx.l10n.commonClose,
            onTap: () => Navigator.of(ctx).pop(),
          ),
          maxHeightFactor: 0.65,
          addBottomInset: false,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
              ...CleanupScale.values.expand((CleanupScale scale) {
                final bool isActive = scale == _scale;
                return <Widget>[
                  ReportActionTile(
                    icon: Icons.groups_rounded,
                    title: scale.localizedLabel(ctx.l10n),
                    subtitle: scale.localizedDescription(ctx.l10n),
                    tone: isActive
                        ? ReportSurfaceTone.accent
                        : ReportSurfaceTone.neutral,
                    trailing: Icon(
                      isActive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 22,
                      color: isActive
                          ? AppColors.primaryDark
                          : AppColors.divider,
                    ),
                    onTap: () {
                      AppHaptics.tap();
                      setState(() => _scale = scale);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  if (scale != CleanupScale.values.last)
                    const SizedBox(height: AppSpacing.sm),
                ];
              }),
            ],
          ),
        );
      },
    );
  }

  void _showDifficultyPicker() {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.createEventDifficultyTitle,
          subtitle: ctx.l10n.createEventDifficultySubtitle,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: ctx.l10n.commonClose,
            onTap: () => Navigator.of(ctx).pop(),
          ),
          maxHeightFactor: 0.6,
          addBottomInset: false,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
              ...EventDifficulty.values.expand((EventDifficulty diff) {
                final bool isActive = diff == _difficulty;
                return <Widget>[
                  ReportActionTile(
                    icon: isActive
                        ? CupertinoIcons.checkmark_shield_fill
                        : CupertinoIcons.shield,
                    title: diff.localizedLabel(ctx.l10n),
                    subtitle: diff.localizedDescription(ctx.l10n),
                    tone: isActive
                        ? ReportSurfaceTone.accent
                        : ReportSurfaceTone.neutral,
                    trailing: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: diff.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () {
                      AppHaptics.tap();
                      setState(() => _difficulty = diff);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  if (diff != EventDifficulty.values.last)
                    const SizedBox(height: AppSpacing.sm),
                ];
              }),
            ],
          ),
        );
      },
    );
  }

  void _showGearPicker() {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return ReportSheetScaffold(
              title: ctx.l10n.createEventGearTitle,
              subtitle: ctx.l10n.createEventGearSubtitle,
              trailing: ReportCircleIconButton(
                icon: CupertinoIcons.xmark,
                semanticLabel: ctx.l10n.commonClose,
                onTap: () => Navigator.of(ctx).pop(),
              ),
              maxHeightFactor: 0.82,
              addBottomInset: false,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              footer: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(ctx).bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      AppHaptics.tap();
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                    child: Text(
                      _gear.isEmpty
                          ? ctx.l10n.commonSkip
                          : ctx.l10n.createEventGearDoneSelectedCount(
                              _gear.length,
                            ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: <Widget>[
                  ReportInfoBanner(
                    title: ctx.l10n.createEventGearMultiselectTitle,
                    message: ctx.l10n.createEventGearMultiselectMessage,
                    icon: CupertinoIcons.bag,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...EventGear.values.expand((EventGear gear) {
                    final bool isActive = _gear.contains(gear);
                    return <Widget>[
                      ReportActionTile(
                        icon: gear.icon,
                        title: gear.localizedLabel(ctx.l10n),
                        tone: isActive
                            ? ReportSurfaceTone.accent
                            : ReportSurfaceTone.neutral,
                        trailing: Icon(
                          isActive
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 22,
                          color: isActive
                              ? AppColors.primaryDark
                              : AppColors.divider,
                        ),
                        onTap: () {
                          AppHaptics.tap();
                          if (!isActive &&
                              _gear.length >= kEditEventGearMaxCount) {
                            AppHaptics.warning();
                            AppSnack.show(
                              context,
                              message: ctx.l10n.editEventGearLimitReached(
                                kEditEventGearMaxCount,
                              ),
                              type: AppSnackType.warning,
                            );
                            return;
                          }
                          setModalState(() {
                            if (isActive) {
                              _gear.remove(gear);
                            } else {
                              _gear.add(gear);
                            }
                          });
                          setState(() {});
                        },
                      ),
                      if (gear != EventGear.values.last)
                        const SizedBox(height: AppSpacing.sm),
                    ];
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _scrollToFirstError() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    final String title = _titleController.text.trim();
    if (editEventTitleIssueKey(title) != null) {
      _titleFocus.requestFocus();
      final BuildContext? ctx = _titleFocus.context;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: AppMotion.fast,
          curve: AppMotion.smooth,
        );
      }
      if (!mounted) {
        return;
      }
      return;
    }
    final String description = _descriptionController.text.trim();
    if (editEventDescriptionIssueKey(description) != null) {
      _descriptionFocus.requestFocus();
      final BuildContext? ctx = _descriptionFocus.context;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: AppMotion.fast,
          curve: AppMotion.smooth,
        );
      }
      if (!mounted) {
        return;
      }
      return;
    }
    if (editEventMaxParticipantsIssueKey(
          _maxParticipantsController.text.trim(),
        ) !=
        null) {
      _maxParticipantsFocus.requestFocus();
      final BuildContext? ctx = _maxParticipantsFocus.context;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: AppMotion.fast,
          curve: AppMotion.smooth,
        );
      }
    }
  }

  Future<void> _showDuplicateSubmitDialog(AppError error) async {
    final DuplicateEventConflictUi? dup = duplicateEventConflictUiFromAppError(
      error,
    );
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

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (!_isValid) {
      setState(() => _showValidationErrors = true);
      AppHaptics.warning();
      await _scrollToFirstError();
      return;
    }

    final List<ConnectivityResult> connectivity = await ConnectivityGate.check();
    if (!mounted) {
      return;
    }
    final bool online = ConnectivityGate.isOnline(connectivity);
    if (!online) {
      if (!mounted) {
        return;
      }
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

    final DateTime startDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final DateTime endCal = DateUtils.dateOnly(_selectedDate);
    final DateTime endDt = DateTime(
      endCal.year,
      endCal.month,
      endCal.day,
      _endTime.hour,
      _endTime.minute,
    );

    final String titleTrimmed = _titleController.text.trim();
    final String descriptionTrimmed = _descriptionController.text.trim();
    final int? maxParticipants = editEventParsedMaxParticipants(
      _maxParticipantsController.text.trim(),
    );
    final List<EventGear> gearList = _gear.toList(growable: false)
      ..sort((EventGear a, EventGear b) => a.name.compareTo(b.name));

    final EventUpdatePayload payload = _initialSnapshot.buildPartialPayload(
      titleTrimmed: titleTrimmed,
      descriptionTrimmed: descriptionTrimmed,
      maxParticipants: maxParticipants,
      scheduledAtUtc: startDt.toUtc(),
      endAtUtc: endDt.toUtc(),
      category: _category,
      gear: gearList,
      scale: _scale,
      difficulty: _difficulty,
    );

    if (payload.toPatchJson().isEmpty) {
      if (!mounted) {
        return;
      }
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.editEventNoChangesToSave,
        type: AppSnackType.warning,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await EventsRepositoryRegistry.instance.updateEventDetails(
        _event.id,
        payload,
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
      message: context.l10n.eventsEventUpdated,
      type: AppSnackType.success,
    );
    Navigator.of(context, rootNavigator: true).pop();
  }

  String? _titleError(AppLocalizations l10n) {
    if (!_showValidationErrors) {
      return null;
    }
    final String key =
        editEventTitleIssueKey(_titleController.text.trim()) ?? '';
    if (key == 'tooShort') {
      return l10n.createEventTitleMinLength;
    }
    if (key == 'tooLong') {
      return l10n.editEventTitleTooLong(kEditEventTitleMaxLength);
    }
    return null;
  }

  String? _descriptionError(AppLocalizations l10n) {
    if (!_showValidationErrors) {
      return null;
    }
    if (editEventDescriptionIssueKey(_descriptionController.text.trim()) ==
        'tooLong') {
      return l10n.editEventDescriptionTooLong(kEditEventDescriptionMaxLength);
    }
    return null;
  }

  String? _maxParticipantsError(AppLocalizations l10n) {
    if (!_showValidationErrors) {
      return null;
    }
    final String key =
        editEventMaxParticipantsIssueKey(
          _maxParticipantsController.text.trim(),
        ) ??
        '';
    if (key == 'invalid') {
      return l10n.editEventMaxParticipantsInvalid;
    }
    if (key == 'range') {
      return l10n.editEventMaxParticipantsRange(
        kEditEventMaxParticipantsMin,
        kEditEventMaxParticipantsMax,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        unawaited(_requestClose());
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ReportSheetScaffold(
          title: l10n.eventsEditEventTitle,
          subtitle: _event.siteName,
          headerDividerGap: AppSpacing.lg,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Tooltip(
                message: l10n.editEventHelpButtonTooltip,
                child: ReportCircleIconButton(
                  icon: CupertinoIcons.info_circle,
                  semanticLabel: l10n.editEventHelpButtonTooltip,
                  onTap: () {
                    AppHaptics.tap();
                    showEditEventHelpSheet(context);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ReportCircleIconButton(
                icon: CupertinoIcons.xmark,
                semanticLabel: l10n.commonClose,
                onTap: () {
                  AppHaptics.tap();
                  unawaited(_requestClose());
                },
              ),
            ],
          ),
          footer: PrimaryButton(
            label: l10n.eventsEditEventSave,
            enabled: _isDirty && _networkOnline,
            isLoading: _submitting,
            onPressed: _isDirty && !_submitting && _networkOnline
                ? () => unawaited(_submit())
                : null,
          ),
          child: FadeTransition(
            opacity: _entranceFade,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Semantics(
                container: true,
                label: '${l10n.eventsEditEventTitle}. ${_event.siteName}',
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (!_networkOnline) ...<Widget>[
                        Semantics(
                          container: true,
                          label: l10n.editEventOfflineSave,
                          child: Material(
                            color: AppColors.accentWarning.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.cloud_off_outlined,
                                    size: AppSpacing.iconSm,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      l10n.editEventOfflineSave,
                                      style: AppTypography.eventsSupportingCaption(
                                        textTheme,
                                      ).copyWith(color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (!_event.moderationApproved) ...<Widget>[
                        Semantics(
                          container: true,
                          label: l10n.editEventPendingModerationBanner,
                          child: Material(
                            color: AppColors.accentWarning.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                l10n.editEventPendingModerationBanner,
                                style: AppTypography.eventsSupportingCaption(
                                  textTheme,
                                ).copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      TextField(
                        focusNode: _titleFocus,
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        maxLength: kEditEventTitleMaxLength,
                        style: AppTypography.eventsEditFormFieldPrimary(textTheme),
                        buildCounter:
                            (
                              BuildContext _, {
                              required int currentLength,
                              required bool isFocused,
                              required int? maxLength,
                            }) {
                              return editEventLengthCounter(
                                textTheme,
                                currentLength,
                                maxLength ?? kEditEventTitleMaxLength,
                              );
                            },
                        decoration: editEventTextFieldDecoration(
                          textTheme,
                          labelText: l10n.createEventTitleLabel,
                          errorText: _titleError(l10n),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        focusNode: _descriptionFocus,
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: kEditEventDescriptionMaxLength,
                        style: AppTypography.eventsSearchFieldText(textTheme).copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        buildCounter:
                            (
                              BuildContext _, {
                              required int currentLength,
                              required bool isFocused,
                              required int? maxLength,
                            }) {
                              return editEventLengthCounter(
                                textTheme,
                                currentLength,
                                maxLength ?? kEditEventDescriptionMaxLength,
                              );
                            },
                        decoration: editEventTextFieldDecoration(
                          textTheme,
                          labelText: l10n.createEventDescriptionLabel,
                          errorText: _descriptionError(l10n),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      EventFormPickerTile(
                        label: l10n.createEventFieldType,
                        value: _category.localizedLabel(l10n),
                        icon: _category.icon,
                        placeholder: l10n.createEventPlaceholderType,
                        onTap: _showCategoryPicker,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_event.status == EcoEventStatus.upcoming) ...<Widget>[
                        Text(
                          l10n.createEventScheduleDateLabel,
                          style: AppTypography.eventsSheetSectionLabel(textTheme),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        EventCalendar(
                          selectedDate: _selectedDate,
                          onDateSelected: (DateTime d) {
                            setState(() {
                              _selectedDate = DateUtils.dateOnly(d);
                              final ({EventTime start, EventTime end}) c =
                                  clampCreateOrUpcomingSchedule(
                                dateOnly: _selectedDate,
                                start: _startTime,
                                end: _endTime,
                                now: DateTime.now(),
                              );
                              _startTime = c.start;
                              _endTime = c.end;
                            });
                            _scheduleConflictPreviewDebounced();
                          },
                        ),
                      ] else ...<Widget>[
                        EventCalendar(
                          selectedDate: _selectedDate,
                          onDateSelected: (DateTime d) {
                            setState(() {
                              _selectedDate = d;
                              final DateTime dateOnly = DateUtils.dateOnly(d);
                              final DateTime now = DateTime.now();
                              final ({EventTime start, EventTime end}) c =
                                  clampInProgressEditSchedule(
                                dateOnly: dateOnly,
                                start: _startTime,
                                end: _endTime,
                                now: now,
                              );
                              _startTime = c.start;
                              _endTime = c.end;
                            });
                            _scheduleConflictPreviewDebounced();
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Builder(
                        builder: (BuildContext context) {
                          final ({DateTime? minStart, DateTime? minEnd}) b =
                              _editPickerBounds();
                          return TimeRangePicker(
                            startTime: _startTime.toTimeOfDay(),
                            endTime: _endTime.toTimeOfDay(),
                            hasError:
                                _showValidationErrors &&
                                (!_isTimeValid || _editScheduleIssue() != null),
                            minimumStartPickerTime: b.minStart,
                            minimumEndPickerTime: b.minEnd,
                            maximumEndPickerTime: pickerMaximumForEndSameCalendarDay(),
                            onStartChanged: (TimeOfDay t) {
                              setState(() {
                                _startTime = EventTimeUI.fromTimeOfDay(t);
                                if (_event.status == EcoEventStatus.inProgress) {
                                  if (!EcoEvent.isValidRange(_startTime, _endTime)) {
                                    final DateTime sdt = eventScheduleInstantLocal(
                                      DateUtils.dateOnly(_selectedDate),
                                      _startTime,
                                    );
                                    _endTime = eventTimeFromDateTime(
                                      sdt.add(const Duration(hours: 2)),
                                    );
                                  }
                                  _endTime = clampEndTimeToEventDay(
                                    dateOnly: DateUtils.dateOnly(_selectedDate),
                                    end: _endTime,
                                    start: _startTime,
                                  );
                                } else {
                                  final DateTime si = eventScheduleInstantLocal(
                                    DateUtils.dateOnly(_selectedDate),
                                    _startTime,
                                  );
                                  final DateTime ei = eventScheduleInstantLocal(
                                    DateUtils.dateOnly(_selectedDate),
                                    _endTime,
                                  );
                                  if (!ei.isAfter(si)) {
                                    _endTime = eventTimeFromDateTime(
                                      ceilToMinuteGrid(
                                        si.add(const Duration(hours: 1)),
                                      ),
                                    );
                                  }
                                  _endTime = clampEndTimeToEventDay(
                                    dateOnly: DateUtils.dateOnly(_selectedDate),
                                    end: _endTime,
                                    start: _startTime,
                                  );
                                }
                              });
                              _scheduleConflictPreviewDebounced();
                            },
                            onEndChanged: (TimeOfDay t) {
                              setState(() {
                                _endTime = clampEndTimeToEventDay(
                                  dateOnly: DateUtils.dateOnly(_selectedDate),
                                  end: EventTimeUI.fromTimeOfDay(t),
                                  start: _startTime,
                                );
                              });
                              _scheduleConflictPreviewDebounced();
                            },
                          );
                        },
                      ),
                      if (_scheduleConflictHint != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        EditEventScheduleConflictCallout(
                          bodyText: l10n.eventsScheduleConflictPreviewBody(
                            _scheduleConflictHint!.title,
                            _formatConflictWhen(
                              context,
                              _scheduleConflictHint!.scheduledAt,
                            ),
                          ),
                        ),
                      ],
                      if (_schedulePreviewFailed) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l10n.editEventSchedulePreviewFailed,
                            style: AppTypography.eventsSupportingCaption(textTheme),
                          ),
                        ),
                      ],
                      if (_showValidationErrors && !_isTimeValid) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.createEventEndTimeError,
                          style: AppTypography.eventsCaptionStrong(
                            textTheme,
                            color: AppColors.accentDanger,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (_showValidationErrors &&
                          _isTimeValid &&
                          _editScheduleIssue() ==
                              ScheduleValidationIssue.endAfterLocalDayEnd) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.createEventScheduleEndAfterDayError,
                          style: AppTypography.eventsCaptionStrong(
                            textTheme,
                            color: AppColors.accentDanger,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (_showValidationErrors &&
                          _isTimeValid &&
                          _editScheduleIssue() ==
                              ScheduleValidationIssue.startTooSoon) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.createEventScheduleStartInPast(
                            kEventScheduleMinLead.inMinutes,
                          ),
                          style: AppTypography.eventsCaptionStrong(
                            textTheme,
                            color: AppColors.accentDanger,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (_showValidationErrors &&
                          _isTimeValid &&
                          _editScheduleIssue() ==
                              ScheduleValidationIssue.endTooSoon) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.createEventScheduleEndInPast(
                            kEventScheduleMinLead.inMinutes,
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.accentDanger,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        focusNode: _maxParticipantsFocus,
                        controller: _maxParticipantsController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.eventsEditFormFieldPrimary(textTheme),
                        decoration: editEventTextFieldDecoration(
                          textTheme,
                          labelText: l10n.createEventFieldVolunteerCap,
                          hintText: l10n.createEventVolunteerCapCustomHint,
                          errorText: _maxParticipantsError(l10n),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      EventFormPickerTile(
                        label: l10n.createEventFieldTeamSize,
                        value: _scale.localizedLabel(l10n),
                        icon: Icons.groups_rounded,
                        placeholder: l10n.createEventPlaceholderTeamSize,
                        onTap: _showScalePicker,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      EventFormPickerTile(
                        label: l10n.createEventFieldDifficulty,
                        value: _difficulty.localizedLabel(l10n),
                        icon: CupertinoIcons.shield,
                        trailingDot: _difficulty.color,
                        placeholder: l10n.createEventPlaceholderDifficulty,
                        onTap: _showDifficultyPicker,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      EventFormGearSummaryTile(
                        selectedGear: _gear,
                        onTap: _showGearPicker,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

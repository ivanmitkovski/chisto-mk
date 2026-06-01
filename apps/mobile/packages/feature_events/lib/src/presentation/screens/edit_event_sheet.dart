library;

import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/l10n/duplicate_event_conflict.dart';
import 'package:chisto_infrastructure/core/network/connectivity_gate.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/application/events_providers.dart';
import 'package:feature_events/src/application/schedule_conflict_preview_controller.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/event_update_payload.dart';
import 'package:feature_events/src/presentation/event_ui_mappers.dart';
import 'package:feature_events/src/presentation/utils/edit_event_form_state.dart';
import 'package:feature_events/src/presentation/utils/event_schedule_constraints.dart';
import 'package:feature_events/src/presentation/utils/events_localized_strings.dart';
import 'package:feature_events/src/presentation/widgets/edit_event/edit_event_help_sheet.dart';
import 'package:feature_events/src/presentation/widgets/edit_event/edit_event_schedule_conflict_callout.dart';
import 'package:feature_events/src/presentation/widgets/event_calendar.dart';
import 'package:feature_events/src/presentation/widgets/event_form/event_form_field_primitives.dart';
import 'package:feature_events/src/presentation/widgets/event_form/event_form_gear_sheet_footer.dart';
import 'package:feature_events/src/presentation/widgets/event_form/event_form_picker_tile.dart';
import 'package:feature_events/src/presentation/widgets/events_modal_sheet.dart';
import 'package:feature_events/src/presentation/widgets/time_range_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

part 'edit_event_sheet_pickers.dart';
part 'edit_event_sheet_submit.dart';

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
  late final ScheduleConflictPreviewController _scheduleConflict;
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
    _scheduleConflict = ScheduleConflictPreviewController(
      eventsRepository: readEventsRepository(),
      isMounted: () => mounted,
      onChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
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

    unawaited(
      ConnectivityGate.check().then((List<ConnectivityResult> r) {
        if (!mounted) {
          return;
        }
        setState(() => _networkOnline = ConnectivityGate.isOnline(r));
      }),
    );
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
    _scheduleConflict.dispose();
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

  void _scheduleConflictPreviewDebounced() {
    _scheduleConflict.schedulePreview(
      scheduleValid: _isScheduleValid,
      siteId: _event.siteId,
      startLocal: eventScheduleInstantLocal(
        DateUtils.dateOnly(_selectedDate),
        _startTime,
      ),
      endLocal: eventScheduleInstantLocal(
        DateUtils.dateOnly(_selectedDate),
        _endTime,
      ),
      excludeEventId: _event.id,
    );
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
    if ((discard ?? false) && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
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
                    showEditEventHelpSheet(context);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ReportCircleIconButton(
                icon: CupertinoIcons.xmark,
                semanticLabel: l10n.commonClose,
                onTap: () {
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
                                  const Icon(
                                    Icons.cloud_off_outlined,
                                    size: AppSpacing.iconSm,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      l10n.editEventOfflineSave,
                                      style:
                                          AppTypography.eventsSupportingCaption(
                                            textTheme,
                                          ).copyWith(
                                            color: AppColors.textPrimary,
                                          ),
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
                      DesignSystemTextField(
                        focusNode: _titleFocus,
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        maxLength: kEditEventTitleMaxLength,
                        style: AppTypography.eventsEditFormFieldPrimary(
                          textTheme,
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
                      DesignSystemTextField(
                        focusNode: _descriptionFocus,
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: kEditEventDescriptionMaxLength,
                        style: AppTypography.eventsSearchFieldText(
                          textTheme,
                        ).copyWith(fontWeight: FontWeight.w500, height: 1.35),
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
                          style: AppTypography.eventsSheetSectionLabel(
                            textTheme,
                          ),
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
                            maximumEndPickerTime:
                                pickerMaximumForEndSameCalendarDay(),
                            onStartChanged: (TimeOfDay t) {
                              setState(() {
                                _startTime = EventTimeUI.fromTimeOfDay(t);
                                if (_event.status ==
                                    EcoEventStatus.inProgress) {
                                  if (!EcoEvent.isValidRange(
                                    _startTime,
                                    _endTime,
                                  )) {
                                    final DateTime sdt =
                                        eventScheduleInstantLocal(
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
                      if (_scheduleConflict.hint != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        EditEventScheduleConflictCallout(
                          bodyText: l10n.eventsScheduleConflictPreviewBody(
                            _scheduleConflict.hint!.title,
                            _scheduleConflict.formatConflictWhen(
                              context,
                              _scheduleConflict.hint!.scheduledAt,
                            ),
                          ),
                        ),
                      ],
                      if (_scheduleConflict.previewFailed) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l10n.editEventSchedulePreviewFailed,
                            style: AppTypography.eventsSupportingCaption(
                              textTheme,
                            ),
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
                              ScheduleValidationIssue
                                  .endAfterLocalDayEnd) ...<Widget>[
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
                      DesignSystemTextField(
                        focusNode: _maxParticipantsFocus,
                        controller: _maxParticipantsController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.eventsEditFormFieldPrimary(
                          textTheme,
                        ),
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

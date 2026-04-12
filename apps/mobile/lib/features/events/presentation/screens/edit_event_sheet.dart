// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_update_payload.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_calendar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/time_range_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Organizer-only editor for fields supported by `PATCH /events/:id`.
class EditEventSheet extends StatefulWidget {
  const EditEventSheet({super.key, required this.event});

  final EcoEvent event;

  @override
  State<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<EditEventSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxParticipantsController;
  late DateTime _selectedDate;
  late EventTime _startTime;
  late EventTime _endTime;
  late EcoEventCategory _category;
  late Set<EventGear> _gear;
  late CleanupScale _scale;
  late EventDifficulty _difficulty;
  bool _submitting = false;
  bool _showValidationErrors = false;

  EcoEvent get _event => widget.event;

  bool get _isTimeValid => EcoEvent.isValidRange(_startTime, _endTime);

  bool get _isValid =>
      _titleController.text.trim().length >= 3 && _isTimeValid;

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
    _endTime = _event.endTime;
    _category = _event.category;
    _gear = _event.gear.toSet();
    _scale = _event.scale ?? CleanupScale.small;
    _difficulty = _event.difficulty ?? EventDifficulty.easy;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    AppHaptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.createEventCategoryTitle,
          subtitle: ctx.l10n.createEventCategorySubtitle,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: ctx.l10n.commonClose,
            onTap: () {
              AppHaptics.tap();
              Navigator.of(ctx).pop();
            },
          ),
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              for (final EcoEventCategory cat in EcoEventCategory.values) ...<Widget>[
                ListTile(
                  leading: Icon(cat.icon, color: AppColors.primaryDark),
                  title: Text(cat.localizedLabel(ctx.l10n)),
                  trailing: cat == _category
                      ? const Icon(CupertinoIcons.checkmark, color: AppColors.primary)
                      : null,
                  onTap: () {
                    AppHaptics.tap();
                    setState(() => _category = cat);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_isValid) {
      setState(() => _showValidationErrors = true);
      AppHaptics.warning();
      return;
    }
    final int? maxParticipants = () {
      final String t = _maxParticipantsController.text.trim();
      if (t.isEmpty) {
        return null;
      }
      return int.tryParse(t);
    }();
    if (_maxParticipantsController.text.trim().isNotEmpty &&
        (maxParticipants == null || maxParticipants < 2)) {
      setState(() => _showValidationErrors = true);
      AppHaptics.warning();
      AppSnack.show(
        context,
        message: context.l10n.eventsMutationFailedGeneric,
        type: AppSnackType.warning,
      );
      return;
    }

    final DateTime startDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final DateTime endDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final EventUpdatePayload payload = EventUpdatePayload(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      scheduledAtUtc: startDt.toUtc(),
      endAtUtc: endDt.toUtc(),
      maxParticipants: maxParticipants,
      gear: _gear.toList(growable: false),
      scale: _scale,
      difficulty: _difficulty,
    );

    setState(() => _submitting = true);
    try {
      await EventsRepositoryRegistry.instance.updateEventDetails(
        _event.id,
        payload,
      );
    } on AppError catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          message: e.message.isNotEmpty ? e.message : context.l10n.eventsMutationFailedGeneric,
          type: AppSnackType.warning,
        );
      }
      if (mounted) {
        setState(() => _submitting = false);
      }
      return;
    } on Object {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsMutationFailedGeneric,
          type: AppSnackType.warning,
        );
      }
      if (mounted) {
        setState(() => _submitting = false);
      }
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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ReportSheetScaffold(
        title: context.l10n.eventsEditEventTitle,
        subtitle: _event.siteName,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: context.l10n.commonClose,
          onTap: () {
            AppHaptics.tap();
            Navigator.of(context).pop();
          },
        ),
        footer: PrimaryButton(
          label: context.l10n.eventsEditEventSave,
          enabled: !_submitting,
          onPressed: _submitting ? null : () => unawaited(_submit()),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.l10n.createEventTitleLabel,
                  errorText: _showValidationErrors &&
                          _titleController.text.trim().length < 3
                      ? context.l10n.createEventTitleMinLength
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: context.l10n.createEventDescriptionLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.createEventFieldType),
                subtitle: Text(_category.localizedLabel(context.l10n)),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: _pickCategory,
              ),
              const SizedBox(height: AppSpacing.lg),
              EventCalendar(
                selectedDate: _selectedDate,
                onDateSelected: (DateTime d) {
                  setState(() => _selectedDate = d);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider.withValues(alpha: 0.55),
              ),
              const SizedBox(height: AppSpacing.lg),
              TimeRangePicker(
                startTime: _startTime.toTimeOfDay(),
                endTime: _endTime.toTimeOfDay(),
                hasError: _showValidationErrors && !_isTimeValid,
                onStartChanged: (TimeOfDay t) => setState(
                  () => _startTime = EventTimeUI.fromTimeOfDay(t),
                ),
                onEndChanged: (TimeOfDay t) => setState(
                  () => _endTime = EventTimeUI.fromTimeOfDay(t),
                ),
              ),
              if (_showValidationErrors && !_isTimeValid) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.createEventEndTimeError,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _maxParticipantsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.createEventFieldTeamSize,
                  hintText: context.l10n.createEventPlaceholderTeamSize,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.createEventGearLabel,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: EventGear.values.map((EventGear g) {
                  final bool selected = _gear.contains(g);
                  return FilterChip(
                    label: Text(g.localizedLabel(context.l10n)),
                    selected: selected,
                    onSelected: (bool v) {
                      setState(() {
                        if (v) {
                          _gear.add(g);
                        } else {
                          _gear.remove(g);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<CleanupScale>(
                value: _scale,
                decoration: InputDecoration(
                  labelText: context.l10n.createEventTeamSizeTitle,
                ),
                items: CleanupScale.values
                    .map(
                      (CleanupScale s) => DropdownMenuItem<CleanupScale>(
                        value: s,
                        child: Text(s.localizedLabel(context.l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (CleanupScale? v) {
                  if (v != null) {
                    setState(() => _scale = v);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<EventDifficulty>(
                value: _difficulty,
                decoration: InputDecoration(
                  labelText: context.l10n.createEventDifficultyTitle,
                ),
                items: EventDifficulty.values
                    .map(
                      (EventDifficulty d) => DropdownMenuItem<EventDifficulty>(
                        value: d,
                        child: Text(d.localizedLabel(context.l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (EventDifficulty? v) {
                  if (v != null) {
                    setState(() => _difficulty = v);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/event_ui_mappers.dart';
import 'package:feature_events/src/presentation/utils/events_localized_strings.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_sticky_footer.dart';
import 'package:feature_events/src/presentation/widgets/event_form/event_form_picker_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateEventDetailsSection extends StatelessWidget {
  const CreateEventDetailsSection({
    super.key,
    required this.titleFieldKey,
    required this.categorySectionKey,
    required this.titleController,
    required this.titleFocusNode,
    required this.descriptionFieldKey,
    required this.descriptionFocusNode,
    required this.descriptionController,
    required this.showTitleError,
    required this.showCategoryError,
    required this.selectedCategory,
    required this.selectedScale,
    required this.selectedDifficulty,
    required this.selectedGear,
    required this.maxParticipants,
    required this.onTitleChanged,
    required this.onCategoryTap,
    required this.onVolunteerCapTap,
    required this.onScaleTap,
    required this.onDifficultyTap,
    required this.onGearTap,
    this.onDescriptionChanged,
  });

  final Key titleFieldKey;
  final Key categorySectionKey;
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final Key descriptionFieldKey;
  final FocusNode descriptionFocusNode;
  final TextEditingController descriptionController;
  final bool showTitleError;
  final bool showCategoryError;
  final EcoEventCategory? selectedCategory;
  final CleanupScale? selectedScale;
  final EventDifficulty? selectedDifficulty;
  final Set<EventGear> selectedGear;
  final int? maxParticipants;
  final VoidCallback onTitleChanged;
  final VoidCallback onCategoryTap;
  final VoidCallback onVolunteerCapTap;
  final VoidCallback onScaleTap;
  final VoidCallback onDifficultyTap;
  final VoidCallback onGearTap;
  final ValueChanged<String>? onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KeyedSubtree(
          key: titleFieldKey,
          child: _CreateEventTitleField(
            controller: titleController,
            focusNode: titleFocusNode,
            showError: showTitleError,
            onChanged: onTitleChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KeyedSubtree(
          key: categorySectionKey,
          child: EventFormPickerTile(
            label: context.l10n.createEventFieldType,
            value: selectedCategory?.localizedLabel(context.l10n),
            icon: selectedCategory?.icon,
            placeholder: context.l10n.createEventPlaceholderType,
            onTap: onCategoryTap,
            hasError: showCategoryError,
            errorText: context.l10n.createEventTypeRequired,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        EventFormPickerTile(
          key: const ValueKey<String>('create_event_volunteer_cap'),
          label: context.l10n.createEventFieldVolunteerCap,
          value: maxParticipants == null
              ? null
              : context.l10n.createEventVolunteerCapUpTo(maxParticipants!),
          icon: CupertinoIcons.person_3_fill,
          placeholder: context.l10n.createEventVolunteerCapPlaceholderNoLimit,
          onTap: onVolunteerCapTap,
        ),
        const SizedBox(height: AppSpacing.md),
        EventFormPickerTile(
          label: context.l10n.createEventFieldTeamSize,
          value: selectedScale?.localizedLabel(context.l10n),
          icon: Icons.groups_rounded,
          placeholder: context.l10n.createEventPlaceholderTeamSize,
          onTap: onScaleTap,
        ),
        const SizedBox(height: AppSpacing.md),
        EventFormPickerTile(
          label: context.l10n.createEventFieldDifficulty,
          value: selectedDifficulty?.localizedLabel(context.l10n),
          icon: CupertinoIcons.shield,
          trailingDot: selectedDifficulty?.color,
          placeholder: context.l10n.createEventPlaceholderDifficulty,
          onTap: onDifficultyTap,
        ),
        const SizedBox(height: AppSpacing.md),
        EventFormGearSummaryTile(selectedGear: selectedGear, onTap: onGearTap),
        const SizedBox(height: AppSpacing.lg),
        KeyedSubtree(
          key: descriptionFieldKey,
          child: _CreateEventDescriptionField(
            focusNode: descriptionFocusNode,
            controller: descriptionController,
            onChanged: onDescriptionChanged,
          ),
        ),
      ],
    );
  }
}

class _CreateEventTitleField extends StatelessWidget {
  const _CreateEventTitleField({
    required this.controller,
    required this.focusNode,
    required this.showError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showError;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final String trimmed = controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.createEventTitleLabel,
          style: AppTypography.eventsFormLeadHeading(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DesignSystemTextField(
          controller: controller,
          focusNode: focusNode,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          scrollPadding: EdgeInsets.only(
            bottom: CreateEventStickyFooter.scrollBottomReserve + AppSpacing.lg,
          ),
          onChanged: (_) => onChanged(),
          buildCounter:
              (
                BuildContext context, {
                required int currentLength,
                required bool isFocused,
                int? maxLength,
              }) {
                final int max = maxLength ?? 60;
                final String label = context.l10n.createEventTitleCounter(
                  currentLength,
                  max,
                );
                return Semantics(
                  label: label,
                  child: Text(
                    label,
                    style:
                        AppTypography.eventsListCardMeta(
                          Theme.of(context).textTheme,
                        ).copyWith(
                          color: currentLength >= max * 0.9
                              ? AppColors.error
                              : AppColors.textMuted,
                        ),
                  ),
                );
              },
          style: AppTypography.eventsSearchFieldText(
            Theme.of(context).textTheme,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.createEventTitleHint,
            hintStyle: AppTypography.eventsSearchFieldPlaceholder(
              Theme.of(context).textTheme,
            ),
            filled: true,
            fillColor: showError
                ? AppColors.error.withValues(alpha: 0.04)
                : AppColors.panelBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: showError ? AppColors.error : AppColors.divider,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: showError ? AppColors.error : AppColors.divider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: showError ? AppColors.error : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              trimmed.isEmpty
                  ? context.l10n.createEventTitleRequired
                  : context.l10n.createEventTitleMinLength,
              style: AppTypography.eventsCaptionStrong(
                Theme.of(context).textTheme,
                color: AppColors.error,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}

class _CreateEventDescriptionField extends StatelessWidget {
  const _CreateEventDescriptionField({
    required this.controller,
    required this.focusNode,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.createEventDescriptionLabel,
          style: AppTypography.eventsFormLeadHeading(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          context.l10n.createEventDescriptionSubtitle,
          style: AppTypography.eventsListCardMeta(Theme.of(context).textTheme),
        ),
        const SizedBox(height: AppSpacing.sm),
        DesignSystemTextField(
          controller: controller,
          focusNode: focusNode,
          minLines: 3,
          maxLines: 8,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          onChanged: onChanged,
          scrollPadding: EdgeInsets.only(
            bottom: CreateEventStickyFooter.scrollBottomReserve + AppSpacing.lg,
          ),
          style: AppTypography.eventsSearchFieldText(
            Theme.of(context).textTheme,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.createEventDescriptionHint,
            hintStyle: AppTypography.eventsSearchFieldPlaceholder(
              Theme.of(context).textTheme,
            ),
            filled: true,
            fillColor: AppColors.panelBackground,
            counterStyle: AppTypography.eventsListCardMeta(
              Theme.of(context).textTheme,
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

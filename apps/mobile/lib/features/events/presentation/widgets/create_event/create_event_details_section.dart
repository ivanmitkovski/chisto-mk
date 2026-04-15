import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';

class CreateEventDetailsSection extends StatelessWidget {
  const CreateEventDetailsSection({
    super.key,
    required this.titleFieldKey,
    required this.categorySectionKey,
    required this.titleController,
    required this.descriptionController,
    required this.showValidationErrors,
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
  final TextEditingController descriptionController;
  final bool showValidationErrors;
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
            showValidationErrors: showValidationErrors,
            onChanged: onTitleChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KeyedSubtree(
          key: categorySectionKey,
          child: _CreateEventPickerTile(
            label: context.l10n.createEventFieldType,
            value: selectedCategory?.localizedLabel(context.l10n),
            icon: selectedCategory?.icon,
            placeholder: context.l10n.createEventPlaceholderType,
            onTap: onCategoryTap,
            hasError: showValidationErrors && selectedCategory == null,
            errorText: context.l10n.createEventTypeRequired,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CreateEventPickerTile(
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
        _CreateEventPickerTile(
          label: context.l10n.createEventFieldTeamSize,
          value: selectedScale?.localizedLabel(context.l10n),
          icon: Icons.groups_rounded,
          placeholder: context.l10n.createEventPlaceholderTeamSize,
          onTap: onScaleTap,
        ),
        const SizedBox(height: AppSpacing.md),
        _CreateEventPickerTile(
          label: context.l10n.createEventFieldDifficulty,
          value: selectedDifficulty?.localizedLabel(context.l10n),
          icon: CupertinoIcons.shield,
          trailingDot: selectedDifficulty?.color,
          placeholder: context.l10n.createEventPlaceholderDifficulty,
          onTap: onDifficultyTap,
        ),
        const SizedBox(height: AppSpacing.md),
        _CreateEventGearTile(
          selectedGear: selectedGear,
          onTap: onGearTap,
        ),
        const SizedBox(height: AppSpacing.lg),
        _CreateEventDescriptionField(
          controller: descriptionController,
          onChanged: onDescriptionChanged,
        ),
      ],
    );
  }
}

class _CreateEventTitleField extends StatelessWidget {
  const _CreateEventTitleField({
    required this.controller,
    required this.showValidationErrors,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool showValidationErrors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final String trimmed = controller.text.trim();
    final bool titleError =
        showValidationErrors && (trimmed.isEmpty || trimmed.length < 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.createEventTitleLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: currentLength >= max * 0.9
                              ? AppColors.accentDanger
                              : AppColors.textMuted,
                          fontSize: 12,
                        ),
                  ),
                );
              },
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
          decoration: InputDecoration(
            hintText: context.l10n.createEventTitleHint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
            filled: true,
            fillColor: titleError
                ? AppColors.accentDanger.withValues(alpha: 0.04)
                : AppColors.panelBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: titleError ? AppColors.accentDanger : AppColors.divider,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.accentDanger),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: titleError ? AppColors.accentDanger : AppColors.divider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: titleError ? AppColors.accentDanger : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (titleError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              trimmed.isEmpty
                  ? context.l10n.createEventTitleRequired
                  : context.l10n.createEventTitleMinLength,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
      ],
    );
  }
}

class _CreateEventPickerTile extends StatelessWidget {
  const _CreateEventPickerTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.placeholder,
    required this.onTap,
    this.trailingDot,
    this.hasError = false,
    this.errorText,
  });

  final String label;
  final String? value;
  final IconData? icon;
  final String placeholder;
  final VoidCallback onTap;
  final Color? trailingDot;
  final bool hasError;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: hasError
                    ? AppColors.accentDanger.withValues(alpha: 0.04)
                    : AppColors.panelBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radius14),
                border: Border.all(
                  color: hasError
                      ? AppColors.accentDanger
                      : (hasValue
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.divider),
                ),
              ),
              child: Row(
                children: <Widget>[
                  if (icon != null && hasValue) ...<Widget>[
                    Icon(icon, size: 18, color: AppColors.primaryDark),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      hasValue ? value! : placeholder,
                      style: AppTypography.eventsFormFieldValue(
                        Theme.of(context).textTheme,
                        hasValue: hasValue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailingDot != null && hasValue) ...<Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: trailingDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
      ],
    );
  }
}

class _CreateEventGearTile extends StatelessWidget {
  const _CreateEventGearTile({
    required this.selectedGear,
    required this.onTap,
  });

  final Set<EventGear> selectedGear;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasGear = selectedGear.isNotEmpty;
    final String summary = hasGear
        ? selectedGear.map((EventGear g) => g.localizedLabel(context.l10n)).join(', ')
        : context.l10n.createEventGearPlaceholderQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.createEventGearLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: context.l10n.createEventSelectGearSemantic,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radius14),
                border: Border.all(
                  color: hasGear
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.divider,
                ),
              ),
              child: Row(
                children: <Widget>[
                  if (hasGear) ...<Widget>[
                    const Icon(
                      CupertinoIcons.bag_fill,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.eventsFormFieldValue(
                        Theme.of(context).textTheme,
                        hasValue: hasGear,
                      ),
                    ),
                  ),
                  if (hasGear) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radius10,
                        ),
                      ),
                      child: Text(
                        '${selectedGear.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateEventDescriptionField extends StatelessWidget {
  const _CreateEventDescriptionField({
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.createEventDescriptionLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          context.l10n.createEventDescriptionSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 8,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
          decoration: InputDecoration(
            hintText: context.l10n.createEventDescriptionHint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
            filled: true,
            fillColor: AppColors.panelBackground,
            counterStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
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

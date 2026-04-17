import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';

/// Picker row used on create-event details and edit-event — matches design tokens.
class EventFormPickerTile extends StatelessWidget {
  const EventFormPickerTile({
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
          style: AppTypography.eventsFormLeadHeading(Theme.of(context).textTheme),
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
              style: AppTypography.eventsCaptionStrong(
                Theme.of(context).textTheme,
                color: AppColors.accentDanger,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}

/// Opens the multi-select gear sheet — same summary row as create-event stepper.
class EventFormGearSummaryTile extends StatelessWidget {
  const EventFormGearSummaryTile({
    super.key,
    required this.selectedGear,
    required this.onTap,
  });

  final Set<EventGear> selectedGear;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasGear = selectedGear.isNotEmpty;
    final String summary = hasGear
        ? selectedGear
              .map((EventGear g) => g.localizedLabel(context.l10n))
              .join(', ')
        : context.l10n.createEventGearPlaceholderQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.createEventGearLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
                        style: AppTypography.eventsCaptionStrong(
                          Theme.of(context).textTheme,
                          color: AppColors.primaryDark,
                        ).copyWith(fontWeight: FontWeight.w700),
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

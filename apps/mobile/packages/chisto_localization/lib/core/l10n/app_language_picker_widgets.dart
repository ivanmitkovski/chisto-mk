import 'package:chisto_localization/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Rows matching [ProfileLanguageScreen] styling (design system).
class LanguagePickerOptionRow extends StatelessWidget {
  const LanguagePickerOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.showDividerBelow,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDividerBelow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Semantics(
          button: true,
          selected: selected,
          label: label,
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: AppColors.primaryDark,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDividerBelow)
          Divider(
            height: 1,
            thickness: 1,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
            color: AppColors.divider.withValues(alpha: 0.85),
          ),
      ],
    );
  }
}

/// Language list: system default, English, Macedonian, Albanian.
class AppLanguagePickerList extends StatelessWidget {
  const AppLanguagePickerList({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final Locale? current;
  final Future<void> Function(Locale? locale) onSelect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? code = current?.languageCode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LanguagePickerOptionRow(
          label: l10n.profileLanguageOptionSystem,
          selected: current == null,
          onTap: () => onSelect(null),
          showDividerBelow: true,
        ),
        LanguagePickerOptionRow(
          label: l10n.profileLanguageNameEn,
          selected: code == 'en',
          onTap: () => onSelect(const Locale('en')),
          showDividerBelow: true,
        ),
        LanguagePickerOptionRow(
          label: l10n.profileLanguageNameMk,
          selected: code == 'mk',
          onTap: () => onSelect(const Locale('mk')),
          showDividerBelow: true,
        ),
        LanguagePickerOptionRow(
          label: l10n.profileLanguageNameSq,
          selected: code == 'sq',
          onTap: () => onSelect(const Locale('sq')),
          showDividerBelow: false,
        ),
      ],
    );
  }
}

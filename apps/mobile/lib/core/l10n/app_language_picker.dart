import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

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
                      Icon(
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

/// Modal sheet to change app language (same options as profile language).
Future<void> showAppLanguagePicker(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      final AppLocalizations l10n = sheetContext.l10n;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.paddingOf(sheetContext).bottom + AppSpacing.md,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radius18),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.9),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: AppSpacing.sheetHandle,
                height: AppSpacing.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCircle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Text(
                  l10n.profileLanguageScreenTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                ),
                child: ValueListenableBuilder<Locale?>(
                  valueListenable: ServiceLocator.instance.appLocaleOverride,
                  builder: (_, Locale? current, Widget? _) {
                    return AppLanguagePickerList(
                      current: current,
                      onSelect: (Locale? locale) async {
                        AppHaptics.light(sheetContext);
                        await ServiceLocator.instance.setAppLocale(locale);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

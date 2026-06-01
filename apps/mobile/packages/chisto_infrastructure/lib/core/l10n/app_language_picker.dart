import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_localization/core/l10n/app_language_picker_widgets.dart';
import 'package:chisto_localization/core/l10n/context_l10n.dart';
import 'package:chisto_localization/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chisto_localization/core/l10n/app_language_picker_widgets.dart';

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
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
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
                child: Consumer(
                  builder: (_, WidgetRef ref, _) {
                    final Locale? current = ref.watch(
                      appLocaleOverrideProvider,
                    );
                    return AppLanguagePickerList(
                      current: current,
                      onSelect: (Locale? locale) async {
                        await ref
                            .read(appBootstrapProvider)
                            .setAppLocale(locale);
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

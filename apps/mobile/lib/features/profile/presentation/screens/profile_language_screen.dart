import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';

/// Lets the user pick a fixed locale or follow the device language.
class ProfileLanguageScreen extends StatefulWidget {
  const ProfileLanguageScreen({super.key});

  @override
  State<ProfileLanguageScreen> createState() => _ProfileLanguageScreenState();
}

class _ProfileLanguageScreenState extends State<ProfileLanguageScreen> {
  @override
  void initState() {
    super.initState();
    ServiceLocator.instance.appLocaleOverride.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ServiceLocator.instance.appLocaleOverride.removeListener(_onLocaleChanged);
    super.dispose();
  }

  Future<void> _select(Locale? locale) async {
    AppHaptics.tap();
    await ServiceLocator.instance.setAppLocale(locale);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Locale? current = ServiceLocator.instance.appLocaleOverride.value;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  AppBackButton(backgroundColor: AppColors.inputFill),
                  Expanded(
                    child: Text(
                      context.l10n.profileLanguageScreenTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Container(
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
                    children: <Widget>[
                      _LanguageOptionRow(
                        label: context.l10n.profileLanguageOptionSystem,
                        selected: current == null,
                        onTap: () => _select(null),
                        showDividerBelow: true,
                      ),
                      _LanguageOptionRow(
                        label: context.l10n.profileLanguageNameEn,
                        selected:
                            current != null && current.languageCode == 'en',
                        onTap: () => _select(const Locale('en')),
                        showDividerBelow: true,
                      ),
                      _LanguageOptionRow(
                        label: context.l10n.profileLanguageNameMk,
                        selected:
                            current != null && current.languageCode == 'mk',
                        onTap: () => _select(const Locale('mk')),
                        showDividerBelow: true,
                      ),
                      _LanguageOptionRow(
                        label: context.l10n.profileLanguageNameSq,
                        selected:
                            current != null && current.languageCode == 'sq',
                        onTap: () => _select(const Locale('sq')),
                        showDividerBelow: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionRow extends StatelessWidget {
  const _LanguageOptionRow({
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
        Material(
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

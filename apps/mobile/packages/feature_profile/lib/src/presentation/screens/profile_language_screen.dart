import 'package:chisto_infrastructure/core/l10n/app_language_picker.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/theme/app_colors.dart';
import 'package:chisto_infrastructure/core/theme/app_shadows.dart';
import 'package:chisto_infrastructure/core/theme/app_spacing.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_profile/src/presentation/widgets/profile_sub_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the user pick a fixed locale or follow the device language.
class ProfileLanguageScreen extends ConsumerStatefulWidget {
  const ProfileLanguageScreen({super.key});

  @override
  ConsumerState<ProfileLanguageScreen> createState() =>
      _ProfileLanguageScreenState();
}

class _ProfileLanguageScreenState extends ConsumerState<ProfileLanguageScreen> {
  Future<void> _select(Locale? locale) async {
    try {
      await ref.read(appBootstrapProvider).setAppLocale(locale);
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.profileLanguageChangeFailed,
        type: AppSnackType.warning,
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Locale? current = ref.watch(appLocaleOverrideProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ProfileSubScreenHeader(
              title: context.l10n.profileLanguageScreenTitle,
              subtitle: context.l10n.profileLanguageScreenSubtitle,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radius18),
                    boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.9),
                    ),
                  ),
                  child: AppLanguagePickerList(
                    current: current,
                    onSelect: _select,
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

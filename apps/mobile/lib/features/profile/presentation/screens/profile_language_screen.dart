import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/app_language_picker.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_sub_screen_header.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

/// Lets the user pick a fixed locale or follow the device language.
class ProfileLanguageScreen extends ConsumerStatefulWidget {
  const ProfileLanguageScreen({super.key});

  @override
  ConsumerState<ProfileLanguageScreen> createState() =>
      _ProfileLanguageScreenState();
}

class _ProfileLanguageScreenState extends ConsumerState<ProfileLanguageScreen> {
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
    try {
      await ServiceLocator.instance.setAppLocale(locale);
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
    final Locale? current = ServiceLocator.instance.appLocaleOverride.value;

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

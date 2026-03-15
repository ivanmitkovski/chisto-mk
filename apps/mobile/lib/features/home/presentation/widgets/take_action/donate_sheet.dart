import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/share_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

enum DonateOption { oneTime, monthly }

class DonateSheet extends StatelessWidget {
  const DonateSheet({super.key, required this.siteTitle});

  final String siteTitle;

  static Future<DonateOption?> show(BuildContext context, {required String siteTitle}) {
    AppHaptics.tap();
    return showModalBottomSheet<DonateOption>(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) => DonateSheet(siteTitle: siteTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Support cleanup efforts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your contribution helps organize cleanups and keep sites healthy.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ShareActionTile(
                icon: Icons.favorite_rounded,
                title: 'One-time donation',
                subtitle: 'Give once to support this cause',
                onTap: () => _pop(context, DonateOption.oneTime),
              ),
              ShareActionTile(
                icon: Icons.repeat_rounded,
                title: 'Monthly contribution',
                subtitle: 'Recurring support for ongoing cleanups',
                onTap: () => _pop(context, DonateOption.monthly),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pop(BuildContext context, DonateOption option) {
    AppHaptics.tap();
    Navigator.of(context).pop(option);
  }
}

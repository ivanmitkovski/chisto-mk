import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';

/// Close control for [ReportDetailSheet] with optional refresh/sync affordance.
class ReportDetailCloseTrailing extends StatelessWidget {
  const ReportDetailCloseTrailing({
    super.key,
    required this.isRefreshing,
    required this.semanticLabel,
  });

  final bool isRefreshing;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            if (isRefreshing)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.tap();
                  Navigator.of(context, rootNavigator: true).pop();
                },
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.8),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: AppMotion.emphasized,
                    switchOutCurve: AppMotion.emphasized,
                    child: Icon(
                      isRefreshing ? Icons.sync_rounded : Icons.close_rounded,
                      key: ValueKey<bool>(isRefreshing),
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
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

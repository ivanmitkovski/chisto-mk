import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppSnackType {
  info,
  success,
  warning,
  error,
}

class AppSnack {
  const AppSnack._();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show(
    BuildContext context, {
    required String message,
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(milliseconds: 1400),
  }) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return null;

    _triggerHaptic(type);
    messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        padding: EdgeInsets.zero,
        content: _AppSnackCard(
          message: message,
          type: type,
        ),
      ),
    );
  }

  static void _triggerHaptic(AppSnackType type) {
    switch (type) {
      case AppSnackType.info:
        HapticFeedback.selectionClick();
      case AppSnackType.success:
        HapticFeedback.lightImpact();
      case AppSnackType.warning:
        HapticFeedback.mediumImpact();
      case AppSnackType.error:
        HapticFeedback.heavyImpact();
    }
  }
}

class _AppSnackCard extends StatelessWidget {
  const _AppSnackCard({
    required this.message,
    required this.type,
  });

  final String message;
  final AppSnackType type;

  @override
  Widget build(BuildContext context) {
    final _SnackPalette palette = _SnackPalette.fromType(type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderColor, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: palette.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                palette.icon,
                size: 16,
                color: palette.iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnackPalette {
  const _SnackPalette({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color borderColor;

  factory _SnackPalette.fromType(AppSnackType type) {
    switch (type) {
      case AppSnackType.info:
        return _SnackPalette(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.textPrimary,
          iconBackground: AppColors.inputFill,
          borderColor: AppColors.divider,
        );
      case AppSnackType.success:
        return _SnackPalette(
          icon: Icons.check_rounded,
          iconColor: AppColors.primaryDark,
          iconBackground: AppColors.primary.withValues(alpha: 0.15),
          borderColor: AppColors.primary.withValues(alpha: 0.3),
        );
      case AppSnackType.warning:
        return _SnackPalette(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFA66700),
          iconBackground: const Color(0xFFFFF4DB),
          borderColor: const Color(0xFFFFDDA3),
        );
      case AppSnackType.error:
        return _SnackPalette(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          iconBackground: const Color(0xFFFDECEC),
          borderColor: const Color(0xFFF8C3C3),
        );
    }
  }
}

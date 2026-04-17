import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';

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
      Duration duration = const Duration(milliseconds: 2600),
  }) {
    _triggerHaptic(context, type);
    // Platform-adaptive behavior:
    // - iOS/macOS: lightweight top banner (Apple-style).
    // - Android/others: Material floating SnackBar from bottom.
    final TargetPlatform platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      final BuildContext? navigatorContext = Navigator.maybeOf(context)?.context;
      if (navigatorContext == null) return null;

      showGeneralDialog<void>(
        context: navigatorContext,
        barrierDismissible: true,
        barrierLabel: 'app_snack',
        barrierColor: AppColors.transparent,
        transitionDuration: AppMotion.medium,
        pageBuilder: (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return _AppSnackOverlay(
            message: message,
            type: type,
            duration: duration,
          );
        },
        transitionBuilder: (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final CurvedAnimation curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          // Avoid hit-testing while SlideTransition/FractionalTranslation is still
          // laying out (iOS top banner); prevents debugNeedsLayout assertions.
          return IgnorePointer(
            ignoring: animation.isAnimating,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: child,
              ),
            ),
          );
        },
      );

      return null;
    }

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return null;

    messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.transparent,
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

  static void _triggerHaptic(BuildContext context, AppSnackType type) {
    switch (type) {
      case AppSnackType.info:
        AppHaptics.tap(context);
      case AppSnackType.success:
        AppHaptics.success(context);
      case AppSnackType.warning:
        AppHaptics.warning(context);
      case AppSnackType.error:
        AppHaptics.error(context);
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.borderColor, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 18,
            offset: const Offset(0, AppSpacing.radiusSm),
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
                size: AppSpacing.iconSm,
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

class _AppSnackOverlay extends StatefulWidget {
  const _AppSnackOverlay({
    required this.message,
    required this.type,
    required this.duration,
  });

  final String message;
  final AppSnackType type;
  final Duration duration;

  @override
  State<_AppSnackOverlay> createState() => _AppSnackOverlayState();
}

class _AppSnackOverlayState extends State<_AppSnackOverlay> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.duration, () {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _dismiss() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Dismissible(
            key: const ValueKey<String>('app_snack'),
            direction: DismissDirection.up,
            onDismissed: (_) => _dismiss(),
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: _AppSnackCard(
                message: widget.message,
                type: widget.type,
              ),
            ),
          ),
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
          iconColor: AppColors.accentWarningDark,
          iconBackground: AppColors.accentWarning.withValues(alpha: 0.15),
          borderColor: AppColors.accentWarning.withValues(alpha: 0.5),
        );
      case AppSnackType.error:
        return _SnackPalette(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          iconBackground: AppColors.accentDanger.withValues(alpha: 0.08),
          borderColor: AppColors.accentDanger.withValues(alpha: 0.5),
        );
    }
  }
}

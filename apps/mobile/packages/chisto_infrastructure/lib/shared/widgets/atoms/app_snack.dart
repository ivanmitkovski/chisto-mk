import 'dart:async';

import 'package:chisto_infrastructure/core/auth/session_invalidation.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigator_key.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AppSnackType { info, success, warning, error }

class AppSnack {
  const AppSnack._();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? failure(
    BuildContext context, {
    required AppError error,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (SessionInvalidation.shouldHandle(error)) {
      unawaited(SessionInvalidation.fromError(error));
      return null;
    }
    return show(
      context,
      message: localizedAppErrorMessage(context.l10n, error),
      type: error.retryable ? AppSnackType.warning : AppSnackType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows a localized error snack, or triggers session teardown for auth errors.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showError(
    BuildContext context, {
    required AppError error,
    AppSnackType type = AppSnackType.warning,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (SessionInvalidation.shouldHandle(error)) {
      unawaited(SessionInvalidation.fromError(error));
      return null;
    }
    return show(
      context,
      message: localizedAppErrorMessage(context.l10n, error),
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Resolves a context that can show snacks from modal bottom sheets.
  static BuildContext? resolveHostContext(BuildContext context) {
    if (ScaffoldMessenger.maybeOf(context) != null) {
      return context;
    }
    final BuildContext? root = appRootNavigatorKey.currentContext;
    if (root != null) {
      if (ScaffoldMessenger.maybeOf(root) != null ||
          Navigator.maybeOf(root) != null) {
        return root;
      }
    }
    if (Navigator.maybeOf(context) != null) {
      return context;
    }
    return root ?? context;
  }

  /// Modal routes often lack a [Scaffold] ancestor; overlay banner works there.
  static bool _needsOverlayBanner(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return true;
    }
    return context.findAncestorWidgetOfExactType<Scaffold>() == null;
  }

  static void _showOverlayBanner(
    BuildContext context, {
    required String message,
    required AppSnackType type,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final BuildContext? navigatorContext =
        Navigator.maybeOf(context, rootNavigator: true)?.context ??
        Navigator.maybeOf(context)?.context;
    if (navigatorContext == null) {
      assert(() {
        AppLog.verbose('[AppSnack] Dropped message (no navigator): $message');
        return true;
      }());
      return;
    }

    showGeneralDialog<void>(
      context: navigatorContext,
      barrierDismissible: true,
      barrierLabel: 'app_snack',
      barrierColor: AppColors.transparent,
      transitionDuration: AppMotion.medium,
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return _AppSnackOverlay(
              message: message,
              type: type,
              duration: duration,
              actionLabel: actionLabel,
              onAction: onAction,
            );
          },
      transitionBuilder:
          (
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
            return IgnorePointer(
              ignoring: animation.isAnimating,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.12),
                  end: Offset.zero,
                ).animate(curved),
                child: FadeTransition(opacity: curved, child: child),
              ),
            );
          },
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show(
    BuildContext context, {
    required String message,
    AppSnackType type = AppSnackType.info,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final BuildContext? hostContext = resolveHostContext(context);
    if (hostContext == null) {
      assert(() {
        AppLog.verbose('[AppSnack] Dropped message (no host context): $message');
        return true;
      }());
      return null;
    }

    final Duration effectiveDuration =
        duration ?? _defaultDuration(message, hasAction: onAction != null);
    _triggerHaptic(hostContext, type);

    if (_needsOverlayBanner(hostContext)) {
      _showOverlayBanner(
        hostContext,
        message: message,
        type: type,
        duration: effectiveDuration,
        actionLabel: actionLabel,
        onAction: onAction,
      );
      return null;
    }

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      hostContext,
    );
    if (messenger == null) {
      assert(() {
        AppLog.verbose(
          '[AppSnack] Dropped message (no ScaffoldMessenger): $message',
        );
        return true;
      }());
      return null;
    }

    messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        duration: effectiveDuration,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        padding: EdgeInsets.zero,
        content: DefaultTextStyle.merge(
          style: Theme.of(hostContext).textTheme.bodyMedium!.copyWith(
            decoration: TextDecoration.none,
          ),
          child: _AppSnackCard(
            message: message,
            type: type,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ),
      ),
    );
  }

  static Duration _defaultDuration(String message, {required bool hasAction}) {
    if (hasAction) return const Duration(seconds: 4);
    final int extraMs = (message.length * 35).clamp(0, 5400);
    return Duration(milliseconds: 2600 + extraMs);
  }

  static void _triggerHaptic(BuildContext context, AppSnackType type) {
    switch (type) {
      case AppSnackType.info:
        break;
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
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppSnackType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final _SnackPalette palette = _SnackPalette.fromType(type);
    final TextStyle messageStyle = AppTypography.textTheme.bodySmall!.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
      height: 1.35,
      decoration: TextDecoration.none,
      decorationColor: AppColors.transparent,
    );
    final bool hasAction = actionLabel != null && onAction != null;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: AppColors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: palette.borderColor, width: 1),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 18,
                offset: Offset(0, AppSpacing.radiusSm),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: DefaultTextStyle(
              style: messageStyle,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _SnackLeadingIcon(palette: palette),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          message,
                          style: messageStyle,
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: true,
                            applyHeightToLastDescent: false,
                          ),
                        ),
                        if (hasAction) ...<Widget>[
                          const SizedBox(height: AppSpacing.xxs),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.maybeOf(
                                  context,
                                )?.hideCurrentSnackBar(
                                  reason: SnackBarClosedReason.hide,
                                );
                                onAction!();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                actionLabel!,
                                style: AppTypography.textTheme.labelLarge!
                                    .copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackLeadingIcon extends StatelessWidget {
  const _SnackLeadingIcon({required this.palette});

  final _SnackPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hidden: true,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
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
    );
  }
}

class _AppSnackOverlay extends StatefulWidget {
  const _AppSnackOverlay({
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppSnackType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

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

  void _onAction() {
    _dismiss();
    widget.onAction?.call();
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
                actionLabel: widget.actionLabel,
                onAction: widget.onAction == null ? null : _onAction,
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

  factory _SnackPalette.fromType(AppSnackType type) {
    switch (type) {
      case AppSnackType.info:
        return const _SnackPalette(
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
          iconBackground: AppColors.error.withValues(alpha: 0.08),
          borderColor: AppColors.error.withValues(alpha: 0.5),
        );
    }
  }

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color borderColor;
}

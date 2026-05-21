import 'dart:async';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

class AppErrorView extends StatefulWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.onLogout,
    this.retryFootnote,
    this.autoRecoverSession = true,
  });

  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onLogout;
  final String? retryFootnote;

  /// When true and [error] is session-invalid, navigates to sign-in automatically.
  final bool autoRecoverSession;

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  bool _recovered = false;

  bool get _isSessionInvalidError =>
      widget.error.indicatesInvalidOrEndedSession;

  @override
  void initState() {
    super.initState();
    if (widget.autoRecoverSession && _isSessionInvalidError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_recoverSession());
      });
    }
  }

  Future<void> _recoverSession() async {
    if (_recovered) return;
    _recovered = true;
    if (widget.onLogout != null) {
      widget.onLogout!();
      return;
    }
    await AppBootstrap.instance.authRepository.invalidateLocalSession();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _handleLogoutTap() async {
    await _recoverSession();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppSpacing.avatarLg,
              height: AppSpacing.avatarLg,
              decoration: BoxDecoration(
                color: AppColors.accentDanger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: AppSpacing.xl,
                color: AppColors.accentDanger,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              localizedAppErrorMessage(context.l10n, widget.error),
              style: AppTypography.emptyStateTitle,
              textAlign: TextAlign.center,
            ),
            if (_isSessionInvalidError) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => unawaited(_handleLogoutTap()),
                icon: const Icon(Icons.logout_rounded),
                label: Text(context.l10n.profileSignOutTile),
              ),
            ],
            if (widget.error.retryable && widget.onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.commonTryAgain),
              ),
            ],
            if (widget.retryFootnote != null &&
                widget.error.retryable &&
                widget.onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.retryFootnote!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

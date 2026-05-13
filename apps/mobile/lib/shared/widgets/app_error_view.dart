import 'dart:async';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.onLogout,
    this.retryFootnote,
  });

  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onLogout;

  /// Optional hint shown below the retry CTA (e.g. upcoming automatic retry).
  final String? retryFootnote;

  bool get _isSessionInvalidError => error.indicatesInvalidOrEndedSession;

  Future<void> _handleLogout(BuildContext context) async {
    if (onLogout != null) {
      onLogout!();
      return;
    }
    await ServiceLocator.instance.authRepository.invalidateLocalSession();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (Route<dynamic> route) => false,
    );
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
              localizedAppErrorMessage(context.l10n, error),
              style: AppTypography.emptyStateTitle,
              textAlign: TextAlign.center,
            ),
            if (_isSessionInvalidError) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => unawaited(_handleLogout(context)),
                icon: const Icon(Icons.logout_rounded),
                label: Text(context.l10n.profileSignOutTile),
              ),
            ],
            if (error.retryable && onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.commonTryAgain),
              ),
            ],
            if (retryFootnote != null &&
                error.retryable &&
                onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                retryFootnote!,
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

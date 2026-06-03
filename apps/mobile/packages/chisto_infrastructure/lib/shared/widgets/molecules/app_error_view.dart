import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

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
    await readRoot(authRepositoryProvider).invalidateLocalSession();
    if (!mounted) return;
    AppNavigation.goSignInAndClearStack();
  }

  Future<void> _handleLogoutTap() async {
    await _recoverSession();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      iconVariant: AppEmptyStateIconVariant.error,
      title: localizedAppErrorMessage(context.l10n, widget.error),
      contentBelowSubtitle: widget.retryFootnote != null &&
              widget.error.retryable &&
              widget.onRetry != null
          ? Text(
              widget.retryFootnote!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                height: 1.35,
              ),
            )
          : null,
      action: _isSessionInvalidError
          ? AppButton.primary(
              label: context.l10n.profileSignOutTile,
              onPressed: () => unawaited(_handleLogoutTap()),
              leadingIcon: const Icon(Icons.logout_rounded, size: 20),
            )
          : widget.error.retryable && widget.onRetry != null
          ? AppButton.primary(
              label: context.l10n.commonTryAgain,
              onPressed: widget.onRetry,
              leadingIcon: const Icon(Icons.refresh_rounded, size: 20),
            )
          : null,
    );
  }
}

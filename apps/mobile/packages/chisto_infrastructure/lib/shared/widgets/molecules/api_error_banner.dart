import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class ApiErrorBanner extends StatefulWidget {
  const ApiErrorBanner({
    super.key,
    this.message,
    this.error,
    this.onDismiss,
    this.onRetry,
    this.detail,
  }) : assert(message != null || error != null);

  final String? message;
  final AppError? error;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;
  final String? detail;

  @override
  State<ApiErrorBanner> createState() => _ApiErrorBannerState();
}

class _ApiErrorBannerState extends State<ApiErrorBanner> {
  bool _announced = false;

  String _resolveMessage(AppLocalizations l10n) {
    if (widget.message != null) {
      return widget.message!;
    }
    return localizedAppErrorMessage(l10n, widget.error!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_announced) {
      return;
    }
    _announced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      final String announcement = _resolveMessage(l10n);
      final bool hardFailure =
          widget.error != null && !widget.error!.retryable;
      if (hardFailure) {
        AppHaptics.error(context);
      } else {
        AppHaptics.warning(context);
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        announcement,
        Directionality.of(context),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String displayMessage = _resolveMessage(l10n);
    final String semanticsLabel = widget.detail != null && widget.detail!.isNotEmpty
        ? '$displayMessage ${widget.detail}'
        : displayMessage;

    return Semantics(
      liveRegion: true,
      label: semanticsLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.error_outline_rounded,
                  size: AppSpacing.iconMd,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    displayMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                ),
                if (widget.onDismiss != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Semantics(
                    label: l10n.errorBannerDismiss,
                    button: true,
                    child: IconButton(
                      onPressed: widget.onDismiss,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: AppSpacing.iconMd,
                        color: AppColors.textMuted,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (widget.detail != null && widget.detail!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.iconMd + AppSpacing.sm,
                  top: AppSpacing.xxs,
                ),
                child: Text(
                  widget.detail!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                ),
              ),
            ],
            if (widget.onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                button: true,
                label: l10n.commonTryAgain,
                child: TextButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.commonTryAgain),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

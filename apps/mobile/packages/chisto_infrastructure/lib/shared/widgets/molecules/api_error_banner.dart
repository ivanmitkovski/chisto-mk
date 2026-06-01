import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ApiErrorBanner extends StatelessWidget {
  const ApiErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
    this.detail,
  });

  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String semanticsLabel = detail != null && detail!.isNotEmpty
        ? '$message $detail'
        : message;

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
          color: AppColors.accentDanger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          border: Border.all(
            color: AppColors.accentDanger.withValues(alpha: 0.35),
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
                  color: AppColors.accentDanger,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
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
                if (onDismiss != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Semantics(
                    label: l10n.errorBannerDismiss,
                    button: true,
                    child: IconButton(
                      onPressed: onDismiss,
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
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.iconMd + AppSpacing.sm,
                  top: AppSpacing.xxs,
                ),
                child: Text(
                  detail!,
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
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                button: true,
                label: l10n.errorBannerTryAgain,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.errorBannerTryAgain),
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

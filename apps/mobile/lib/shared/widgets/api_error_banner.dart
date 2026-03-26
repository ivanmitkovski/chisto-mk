import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: AppColors.accentDanger,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                    ),
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Semantics(
                    label: 'Dismiss',
                    button: true,
                    child: IconButton(
                      onPressed: onDismiss,
                      icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
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
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  detail!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                button: true,
                label: 'Try again',
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
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

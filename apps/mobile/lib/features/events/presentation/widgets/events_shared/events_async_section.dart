import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';

/// Shared chrome for event screens: **loading skeleton → error + retry → content**.
///
/// Used by organizer analytics, weather-style blocks, and other async detail sections
/// so retry affordances and surface decoration stay consistent.
class EventsAsyncSection extends StatelessWidget {
  const EventsAsyncSection({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    required this.retryLabel,
    required this.errorMessage,
    required this.skeleton,
    required this.child,
    this.horizontalPadding = AppSpacing.lg,
  });

  final bool isLoading;
  final bool hasError;
  final Future<void> Function() onRetry;
  final String retryLabel;
  final String errorMessage;
  final Widget skeleton;
  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: EventDetailSurfaceDecoration.elevatedCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                errorMessage,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(88, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: isLoading ? null : () => onRetry(),
                  child: Text(retryLabel),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (isLoading) {
      return skeleton;
    }
    return child;
  }
}

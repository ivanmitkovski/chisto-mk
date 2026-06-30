import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Inline feedback when edit-event submit fails validation or has nothing to PATCH.
class EditEventSubmitBanner extends StatelessWidget {
  const EditEventSubmitBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Material(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: AppSpacing.iconSm,
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.eventsSupportingCaption(textTheme)
                      .copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

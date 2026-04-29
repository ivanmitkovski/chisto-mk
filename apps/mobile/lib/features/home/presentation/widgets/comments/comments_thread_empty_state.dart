import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Empty thread placeholder for site comments (sheet or full-screen route).
class CommentsThreadEmptyState extends StatelessWidget {
  const CommentsThreadEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget content = Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.chat_bubble_outline,
                color: AppColors.textMuted,
                size: constraints.maxHeight < 120 ? 24 : 32,
              ),
              SizedBox(
                height: constraints.maxHeight < 120
                    ? AppSpacing.xs
                    : AppSpacing.sm,
              ),
              Text(
                context.l10n.siteCommentsEmptyBody,
                textAlign: TextAlign.center,
                style: constraints.maxHeight < 120
                    ? AppTypography.cardSubtitle.copyWith(
                        color: AppColors.textMuted,
                        height: 1.35,
                        fontSize: 12,
                      )
                    : AppTypography.cardSubtitle.copyWith(
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
              ),
            ],
          ),
        );

        if (!constraints.hasBoundedHeight) {
          return Center(child: content);
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

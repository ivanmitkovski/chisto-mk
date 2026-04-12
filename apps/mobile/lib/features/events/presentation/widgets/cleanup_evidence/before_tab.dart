import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

class BeforeTab extends StatelessWidget {
  const BeforeTab({
    super.key,
    required this.event,
    required this.heroHeight,
    required this.buildImage,
  });

  final EcoEvent event;
  final double heroHeight;
  final Widget Function(String path, {double? height, BoxFit fit}) buildImage;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: buildImage(
              event.siteImageUrl,
              height: heroHeight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.eventsSiteReferencePhotoTitle,
            style:
                textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.eventsSiteReferencePhotoBody,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

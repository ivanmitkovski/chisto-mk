import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:flutter/material.dart';

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
            borderRadius: AppRadii.lg,
            child: buildImage(event.siteImageUrl, height: heroHeight),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.eventsSiteReferencePhotoTitle,
            style: AppTypography.eventsCalendarMonthTitle(textTheme),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.eventsSiteReferencePhotoBody,
            style: AppTypography.eventsListCardMeta(textTheme),
          ),
        ],
      ),
    );
  }
}

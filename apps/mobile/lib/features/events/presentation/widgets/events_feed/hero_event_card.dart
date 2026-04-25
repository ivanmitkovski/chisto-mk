import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';

class HeroEventCard extends StatelessWidget {
  const HeroEventCard({super.key, required this.event, required this.onTap});

  final EcoEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String countdownLabel = eventsCountdownLabel(context.l10n, event.startDateTime);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget card = Semantics(
        button: true,
        label: '${context.l10n.eventsCardOpenTitle}: ${event.title}',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: AppSpacing.md,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: AppSpacing.lg,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              // No [Hero]: thumbnail + [CupertinoPageRoute] + detail [SliverAppBar]
              // caused `_HeroFlight.divert` / manifest.tag mismatches (series replace, pop).
              Material(
                type: MaterialType.transparency,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  child: SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: EcoEventCoverImage(
                      path: event.siteImageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        colorScheme.scrim.withValues(alpha: 0.72),
                      ],
                      stops: const <double>[0.3, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.radiusSm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        countdownLabel,
                        style: AppTypography.eventsCaptionStrong(
                          textTheme,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.radiusSm),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.eventsHeroCardTitle(textTheme),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            event.siteName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.eventsHeroCardMeta(textTheme),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.radiusSm),
                        Text(
                          event.formattedTimeRange,
                          style: AppTypography.eventsHeroCardMeta(textTheme),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.radius10,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radius10),
                  ),
                  child: Text(
                    context.l10n.eventsFeedUpNext,
                    style: AppTypography.badgeLabel.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return card;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: AppMotion.standard,
      curve: AppMotion.emphasized,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}

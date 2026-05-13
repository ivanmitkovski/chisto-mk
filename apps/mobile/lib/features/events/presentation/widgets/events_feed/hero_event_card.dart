import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_card_chrome.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class HeroEventCard extends StatelessWidget {
  const HeroEventCard({super.key, required this.event, required this.onTap});

  final EcoEvent event;
  final VoidCallback onTap;

  static const int _kLocationTooltipCharThreshold = 48;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final DateTime now = DateTime.now();
    final bool showLeadingCountdown =
        !event.startDateTime.isBefore(now);
    final String countdownLabel = eventsCountdownLabel(context.l10n, event.startDateTime);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final bool metaTwoLines =
        textScale > AppSpacing.eventsHeroCardMetaTwoLineTextScaleThreshold;

    final Widget card = Semantics(
      button: true,
      label: showLeadingCountdown
          ? '${context.l10n.eventsCardOpenTitle}: ${event.title}. $countdownLabel. ${event.siteName}'
          : '${context.l10n.eventsCardOpenTitle}: ${event.title}. ${event.siteName}',
      hint: context.l10n.eventsCardOpenSubtitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          onTap: () {
            AppHaptics.softTransition(context);
            onTap();
          },
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: AppCardChrome.discoveryHeroOuter(colorScheme),
            child: SizedBox(
              height: AppSpacing.eventsHeroCardMediaHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Material(
                    type: MaterialType.transparency,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      child: EcoEventCoverImage(
                        path: event.siteImageUrl,
                        width: double.infinity,
                        height: AppSpacing.eventsHeroCardMediaHeight,
                        fit: BoxFit.cover,
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
                            colorScheme.scrim.withValues(alpha: 0.62),
                          ],
                          stops: const <double>[0.32, 1.0],
                        ),
                      ),
                    ),
                  ),
                  if (showLeadingCountdown)
                    Positioned(
                      left: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.scrim.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.radiusSm,
                            vertical: AppSpacing.xxs,
                          ),
                          child: Text(
                            countdownLabel,
                            style: AppTypography.eventsHeroCountdownLabel(textTheme),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(AppSpacing.radius10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.radius10,
                          vertical: AppSpacing.xxs,
                        ),
                        child: Text(
                          context.l10n.eventsFeedUpNext,
                          style: AppTypography.eventsCardPillLabel(
                            textTheme,
                            color: AppColors.textOnDark,
                          ),
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
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.eventsHeroCardTitle(textTheme),
                        ),
                        SizedBox(height: metaTwoLines ? AppSpacing.xs : AppSpacing.xxs),
                        metaTwoLines
                            ? _HeroMetaColumn(
                                siteName: event.siteName,
                                timeRange: event.formattedTimeRange,
                                textTheme: textTheme,
                                showTooltip:
                                    event.siteName.length > _kLocationTooltipCharThreshold,
                              )
                            : _HeroMetaRow(
                                siteName: event.siteName,
                                timeRange: event.formattedTimeRange,
                                textTheme: textTheme,
                                showTooltip:
                                    event.siteName.length > _kLocationTooltipCharThreshold,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

class _HeroMetaRow extends StatelessWidget {
  const _HeroMetaRow({
    required this.siteName,
    required this.timeRange,
    required this.textTheme,
    required this.showTooltip,
  });

  final String siteName;
  final String timeRange;
  final TextTheme textTheme;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final Widget location = Text(
      siteName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.eventsHeroCardMeta(textTheme),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(
          CupertinoIcons.location_solid,
          size: AppSpacing.iconSm * 0.75,
          color: AppColors.textOnDarkMuted,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: showTooltip ? Tooltip(message: siteName, child: location) : location,
        ),
        const SizedBox(width: AppSpacing.radiusSm),
        Text(
          timeRange,
          style: AppTypography.eventsHeroCardMeta(textTheme),
        ),
      ],
    );
  }
}

class _HeroMetaColumn extends StatelessWidget {
  const _HeroMetaColumn({
    required this.siteName,
    required this.timeRange,
    required this.textTheme,
    required this.showTooltip,
  });

  final String siteName;
  final String timeRange;
  final TextTheme textTheme;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final Widget location = Text(
      siteName,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.eventsHeroCardMeta(textTheme),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                CupertinoIcons.location_solid,
                size: AppSpacing.iconSm * 0.75,
                color: AppColors.textOnDarkMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: showTooltip ? Tooltip(message: siteName, child: location) : location,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            timeRange,
            style: AppTypography.eventsHeroCardMeta(textTheme),
          ),
        ),
      ],
    );
  }
}

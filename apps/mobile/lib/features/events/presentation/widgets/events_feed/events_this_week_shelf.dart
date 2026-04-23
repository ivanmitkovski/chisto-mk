import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_date_format.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';

/// Horizontal "this week near you" discovery strip (Skopje calendar week; see conventions).
///
/// While data is loading, the shelf stays collapsed so the feed does not show a second
/// spinner alongside [CupertinoSliverRefreshControl] on [EventsFeedScreen].
class EventsThisWeekShelf extends StatelessWidget {
  const EventsThisWeekShelf({
    super.key,
    required this.events,
    required this.loadFailed,
    required this.onRetry,
    required this.onOpenEvent,
  });

  final List<EcoEvent> events;
  final bool loadFailed;
  final VoidCallback onRetry;
  final ValueChanged<EcoEvent> onOpenEvent;

  static const double _tileWidth = 268;
  static const double _thumbHeight = 80;

  @override
  Widget build(BuildContext context) {
    if (!loadFailed && events.isEmpty) {
      return const SizedBox.shrink();
    }
    if (loadFailed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: _ErrorRow(onRetry: onRetry),
      );
    }

    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SizedBox(
        height: _thumbHeight + AppSpacing.md * 2,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: reduceMotion
              ? const ClampingScrollPhysics()
              : const BouncingScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(width: AppSpacing.sm),
          itemBuilder: (BuildContext context, int i) {
            final EcoEvent e = events[i];
            return _WeekTile(
              event: e,
              onTap: () => onOpenEvent(e),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            context.l10n.eventsDiscoveryThisWeekRetryHint,
            style: AppTypography.eventsBodyMuted(textTheme),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(context.l10n.eventsDiscoveryThisWeekRetry),
        ),
      ],
    );
  }
}

class _WeekTile extends StatelessWidget {
  const _WeekTile({
    required this.event,
    required this.onTap,
  });

  final EcoEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String dateLine = formatEventCalendarDate(context, event.date);
    final String? tail = event.participantCount > 0
        ? context.l10n.eventsCardParticipantsJoined(event.participantCount)
        : null;
    return Semantics(
      button: true,
      label: '${event.title}, $dateLine${tail != null ? ', $tail' : ''}',
      child: Material(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: EventsThisWeekShelf._tileWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusCard),
                    bottomLeft: Radius.circular(AppSpacing.radiusCard),
                  ),
                  child: SizedBox(
                    width: 96,
                    height: EventsThisWeekShelf._thumbHeight,
                    child: EcoEventCoverImage(
                      path: event.siteImageUrl.trim(),
                      height: EventsThisWeekShelf._thumbHeight,
                      width: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.eventsListCardTitle(textTheme),
                        ),
                        const Spacer(),
                        Text(
                          dateLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.eventsListCardMeta(textTheme),
                        ),
                        if (tail != null)
                          Text(
                            tail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.eventsListCardMeta(textTheme),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

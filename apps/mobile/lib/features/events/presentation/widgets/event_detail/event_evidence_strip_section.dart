import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/event_pulse_route_evidence.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_cover_image.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';

/// Horizontal thumbnails for server-backed cleanup evidence (before / after / field).
class EventEvidenceStripSection extends StatelessWidget {
  const EventEvidenceStripSection({
    super.key,
    required this.items,
    this.compactSubtitle = false,
  });

  final List<EventEvidenceStripItem> items;
  final bool compactSubtitle;

  static String labelForKind(BuildContext context, String kind) {
    final String k = kind.toLowerCase();
    if (k == 'before') {
      return context.l10n.eventsEvidenceKindBefore;
    }
    if (k == 'after') {
      return context.l10n.eventsEvidenceKindAfter;
    }
    return context.l10n.eventsEvidenceKindField;
  }

  void _openPreview(
    BuildContext context,
    EventEvidenceStripItem item,
    String kindDisplay,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        final TextTheme textTheme = Theme.of(ctx).textTheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        child: Text(
                          kindDisplay,
                          style: AppTypography.eventsPanelTitle(textTheme),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: ctx.l10n.commonClose,
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(CupertinoIcons.xmark),
                    ),
                  ],
                ),
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: EcoEventCoverImage(
                      path: item.imageUrl,
                      width: double.infinity,
                      height: 320,
                      fit: BoxFit.contain,
                      errorWidget: const Icon(
                        CupertinoIcons.photo,
                        color: AppColors.textMuted,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                if (item.caption != null && item.caption!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Text(
                      item.caption!.trim(),
                      style: AppTypography.eventsBodyProse(textTheme),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: context.l10n.eventsEvidenceStripSemantic,
      child: DecoratedBox(
        decoration: EventDetailSurfaceDecoration.detailModule(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.eventsEvidenceStripTitle,
                style: AppTypography.eventsPanelTitle(textTheme),
              ),
              if (!compactSubtitle) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.eventsEvidenceStripSubtitle,
                  style: AppTypography.eventsSupportingCaption(textTheme),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, int index) => SizedBox(
                    key: ValueKey<int>(index),
                    width: AppSpacing.xs,
                  ),
                  itemBuilder: (BuildContext context, int i) {
                    final EventEvidenceStripItem item = items[i];
                    final String kindDisplay =
                        EventEvidenceStripSection.labelForKind(context, item.kind);
                    return Semantics(
                      button: true,
                      label: context.l10n.eventsEvidenceStripTileSemantic(
                        i + 1,
                        items.length,
                        kindDisplay,
                      ),
                      child: Material(
                        color: AppColors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _openPreview(context, item, kindDisplay),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          child: SizedBox(
                            width: 88,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        EcoEventCoverImage(
                                          path: item.imageUrl,
                                          width: 88,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorWidget: const ColoredBox(
                                            color: AppColors.inputFill,
                                            child: Icon(
                                              CupertinoIcons.photo,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 4,
                                          bottom: 4,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.72),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              child: Text(
                                                kindDisplay,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography
                                                    .eventsCaptionStrong(
                                                  textTheme,
                                                  color: AppColors.white,
                                                )
                                                    .copyWith(fontSize: 10),
                                              ),
                                            ),
                                          ),
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

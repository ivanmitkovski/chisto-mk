import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_labels.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_node.dart';
import 'package:flutter/material.dart';

class SiteHistoryTimelineTile extends StatefulWidget {
  const SiteHistoryTimelineTile({
    super.key,
    required this.entry,
    required this.showLineAbove,
    required this.showLineBelow,
  });

  final SiteHistoryEntry entry;
  final bool showLineAbove;
  final bool showLineBelow;

  @override
  State<SiteHistoryTimelineTile> createState() =>
      _SiteHistoryTimelineTileState();
}

class _SiteHistoryTimelineTileState extends State<SiteHistoryTimelineTile> {
  bool _noteExpanded = false;

  bool get _hasCleanupNavigation =>
      widget.entry.cleanupEventId != null &&
      widget.entry.cleanupEventId!.trim().isNotEmpty;

  bool get _hasExpandableNote {
    final String? note = widget.entry.note?.trim();
    return note != null && note.isNotEmpty && !_hasCleanupNavigation;
  }

  bool get _isInteractive => _hasCleanupNavigation || _hasExpandableNote;

  void _onTap() {
    if (!_isInteractive) return;
    AppHaptics.tap(context);
    if (_hasCleanupNavigation) {
      AppNavigation.pushEventDetail(eventId: widget.entry.cleanupEventId!);
      return;
    }
    setState(() => _noteExpanded = !_noteExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final String title = siteHistoryEntryTitle(context, widget.entry);
    final String relativeTime = siteHistoryRelativeTime(
      context,
      widget.entry.occurredAt,
    );
    final String absoluteDate = siteHistoryAbsoluteDate(
      context,
      widget.entry.occurredAt,
    );
    final String? subtitle = siteHistoryEntrySubtitle(context, widget.entry);
    final bool showNoteBody = _hasExpandableNote && subtitle != null;

    final String semanticLabel = siteHistoryComposeSemanticLabel(
      context,
      widget.entry,
      relativeTime: relativeTime,
      subtitle: subtitle,
      canOpenEvent: _hasCleanupNavigation,
      noteExpanded: _noteExpanded,
    );

    return Semantics(
      container: true,
      button: _isInteractive,
      label: semanticLabel,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ExcludeSemantics(
              child: SiteHistoryTimelineRail(
                showLineAbove: widget.showLineAbove,
                showLineBelow: widget.showLineBelow,
                node: SiteHistoryTimelineNode(kind: widget.entry.kind),
              ),
            ),
            Expanded(
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: _isInteractive ? _onTap : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.sm + 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      height: 1.25,
                                    ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Tooltip(
                              message: absoluteDate,
                              child: Text(
                                relativeTime,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                      height: 1.25,
                                    ),
                              ),
                            ),
                            if (_hasCleanupNavigation) ...<Widget>[
                              const SizedBox(width: AppSpacing.xxs),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null && !showNoteBody) ...<Widget>[
                          const SizedBox(height: AppSpacing.xxs / 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                          ),
                        ],
                        if (showNoteBody) ...<Widget>[
                          const SizedBox(height: AppSpacing.xxs / 2),
                          AnimatedSize(
                            duration: AppMotion.standard,
                            curve: AppMotion.standardCurve,
                            alignment: Alignment.topLeft,
                            child: Text(
                              subtitle,
                              maxLines: _noteExpanded ? null : 3,
                              overflow: _noteExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    height: 1.3,
                                  ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _noteExpanded
                                ? context.l10n.siteHistoryEntryShowLess
                                : context.l10n.siteHistoryEntryShowMore,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SiteHistoryTimelineSectionHeader extends StatelessWidget {
  const SiteHistoryTimelineSectionHeader({
    super.key,
    required this.label,
    required this.showLineAbove,
    required this.showLineBelow,
  });

  final String label;
  final bool showLineAbove;
  final bool showLineBelow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ExcludeSemantics(
              child: SiteHistoryTimelineRail(
                showLineAbove: showLineAbove,
                showLineBelow: showLineBelow,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  label,
                  style: AppTypographySurfaces.homeHistoryStatusCaption(
                    Theme.of(context).textTheme,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

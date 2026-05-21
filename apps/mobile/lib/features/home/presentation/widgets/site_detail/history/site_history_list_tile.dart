import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SiteHistoryListTile extends StatefulWidget {
  const SiteHistoryListTile({
    super.key,
    required this.entry,
    required this.showDividerBelow,
  });

  final SiteHistoryEntry entry;
  final bool showDividerBelow;

  @override
  State<SiteHistoryListTile> createState() => _SiteHistoryListTileState();
}

class _SiteHistoryListTileState extends State<SiteHistoryListTile> {
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
    HapticFeedback.selectionClick();
    if (_hasCleanupNavigation) {
      Navigator.of(context).pushNamed(
        AppRoutes.eventsDetail,
        arguments: EventRouteArguments(eventId: widget.entry.cleanupEventId!),
      );
      return;
    }
    setState(() => _noteExpanded = !_noteExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon = siteHistoryEntryIcon(widget.entry.kind);
    final String title = siteHistoryEntryTitle(context, widget.entry);
    final String relativeTime =
        siteHistoryRelativeTime(context, widget.entry.occurredAt);
    final String absoluteDate =
        siteHistoryAbsoluteDate(context, widget.entry.occurredAt);
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
      child: Column(
        children: <Widget>[
          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: _isInteractive ? _onTap : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
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
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.showDividerBelow)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.avatarLg),
              child: Divider(
                height: 1,
                color: AppColors.divider.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Default inbox preview line caps (Apple Notification Center style).
const int notificationTitleMaxLines = 2;

/// Body preview lines for a single notification row at default text scale.
int notificationBodyMaxLines(BuildContext context) {
  return _scaledMaxLines(context, base: 4);
}

/// Body preview lines for grouped notification headers.
int notificationGroupBodyMaxLines(
  BuildContext context, {
  required bool expanded,
}) {
  return _scaledMaxLines(context, base: expanded ? 6 : 4);
}

int _scaledMaxLines(BuildContext context, {required int base}) {
  final double scale = MediaQuery.textScalerOf(context).scale(1);
  if (scale >= 1.35) {
    return base + 2;
  }
  if (scale >= 1.15) {
    return base + 1;
  }
  return base;
}

/// Ellipsis preview line for notification title/body/summary.
class NotificationPreviewText extends StatelessWidget {
  const NotificationPreviewText({
    super.key,
    required this.text,
    required this.style,
    required this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

/// Type badge chip used in notification rows.
class NotificationTypeBadge extends StatelessWidget {
  const NotificationTypeBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.labelColor,
  });

  final String label;
  final Color backgroundColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.circle,
      ),
      child: Text(
        label,
        style: AppTypography.badgeLabel(
          Theme.of(context).textTheme,
        ).copyWith(color: labelColor, height: 1.1),
      ),
    );
  }
}

/// Meta row: type badge (left), optional unread dot (right of badge area).
class NotificationTileMetaRow extends StatelessWidget {
  const NotificationTileMetaRow({
    super.key,
    required this.badge,
    this.showUnreadDot = false,
    this.trailing,
  });

  final Widget badge;
  final bool showUnreadDot;

  /// Group expand/collapse only — navigation chevrons use [NotificationInboxRowLayout].
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Flexible(child: badge),
        if (showUnreadDot) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
          ),
        ],
        if (trailing != null) ...<Widget>[const Spacer(), trailing!],
      ],
    );
  }
}

/// Inbox row: leading icon, expanding content, timestamp top-right, chevron centered.
class NotificationInboxRowLayout extends StatelessWidget {
  const NotificationInboxRowLayout({
    super.key,
    required this.leading,
    required this.content,
    this.timestamp,
    this.showNavigationChevron = false,
    this.trailingAccessory,
  });

  final Widget leading;
  final Widget content;
  final String? timestamp;
  final bool showNavigationChevron;
  final Widget? trailingAccessory;

  static const double _trailingRailWidth = 40;

  @override
  Widget build(BuildContext context) {
    final bool hasTimestamp = timestamp != null && timestamp!.trim().isNotEmpty;
    final bool hasRail = showNavigationChevron || trailingAccessory != null;
    final bool hasTrailing = hasTimestamp || hasRail;
    final TextTheme theme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(alignment: Alignment.topCenter, child: leading),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: content),
          if (hasTrailing)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: SizedBox(
                width: _trailingRailWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    if (hasTimestamp)
                      Text(
                        timestamp!,
                        textAlign: TextAlign.right,
                        style:
                            AppTypographySurfaces.homeNotificationTileTimestamp(
                              theme,
                            ).copyWith(
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    if (hasRail)
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (trailingAccessory != null) trailingAccessory!,
                              if (showNavigationChevron)
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 22,
                                  color: AppColors.textMuted.withValues(
                                    alpha: 0.85,
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
        ],
      ),
    );
  }
}

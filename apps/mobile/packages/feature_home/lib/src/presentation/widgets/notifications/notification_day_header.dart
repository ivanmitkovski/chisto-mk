import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Inline day label for notification inbox sections (scrolls with content).
class NotificationDaySectionHeader extends StatelessWidget {
  const NotificationDaySectionHeader({
    super.key,
    required this.title,
    this.isFirst = false,
  });

  final String title;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        isFirst ? AppSpacing.xs : AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppTypographySurfaces.homeNotificationDayHeader(
            Theme.of(context).textTheme,
          ),
        ),
      ),
    );
  }
}

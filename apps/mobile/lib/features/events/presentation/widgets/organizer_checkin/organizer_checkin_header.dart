import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/events_typography.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';

/// Toolbar row (back + optional trailing actions) with the title on the next line.
///
/// Matches a common large-title style: navigation first, then the screen headline
/// so long event names never compete with the back control.
class OrganizerCheckInHeader extends StatelessWidget {
  const OrganizerCheckInHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                AppBackButton(backgroundColor: AppColors.inputFill),
                const Spacer(),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.eventsScreenTitle(textTheme).copyWith(
                letterSpacing: -0.35,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}

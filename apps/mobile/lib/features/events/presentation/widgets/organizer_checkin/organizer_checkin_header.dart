import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';

/// Compact iOS-style title row aligned with [PollutionSiteDetailScreen] header.
///
/// [leadingWidth] and [trailingWidth] default to 96 so a centered title lines up
/// when the left slot is the back control and the right holds two compact icon buttons.
class OrganizerCheckInHeader extends StatelessWidget {
  const OrganizerCheckInHeader({
    super.key,
    required this.title,
    this.trailing,
    this.leadingWidth = 96,
    this.trailingWidth = 96,
  });

  final String title;
  final Widget? trailing;

  /// Min width reserved for [AppBackButton] (keeps title centered vs trailing).
  final double leadingWidth;

  /// Min width reserved for [trailing] (use 88 for two icon buttons).
  final double trailingWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: leadingWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: const AppBackButton(),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: trailingWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing ?? const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography_surfaces.dart';
import 'package:flutter/material.dart';

/// Flat helper copy for picker / selection sheets — not tappable, visually distinct
/// from [AppActionTile] rows.
class AppSelectionInstruction extends StatelessWidget {
  const AppSelectionInstruction({
    super.key,
    required this.message,
    this.label,
    this.icon,
    this.showDividerBelow = true,
  });

  final String message;
  final String? label;
  final IconData? icon;
  final bool showDividerBelow;

  String get _semanticsLabel {
    final String? l = label?.trim();
    if (l != null && l.isNotEmpty) {
      return '$l. $message';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle messageStyle =
        AppTypographySurfaces.reportsLocationPickerHint(textTheme);
    final TextStyle? labelStyle = label == null
        ? null
        : AppTypographySurfaces.reportsFormFieldLabel(
            textTheme,
            color: AppColors.textMuted,
          );

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null && labelStyle != null) ...<Widget>[
          ExcludeSemantics(child: Text(label!, style: labelStyle)),
          const SizedBox(height: AppSpacing.xxs),
        ],
        if (icon != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1, right: AppSpacing.xs),
                  child: Icon(icon, size: 17, color: AppColors.textMuted),
                ),
              ),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(message, style: messageStyle),
                ),
              ),
            ],
          )
        else
          ExcludeSemantics(child: Text(message, style: messageStyle)),
        if (showDividerBelow) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.divider.withValues(alpha: 0.85),
          ),
          const SizedBox(height: AppSpacing.md),
        ] else
          const SizedBox(height: AppSpacing.sm),
      ],
    );

    return Semantics(
      header: true,
      container: true,
      label: _semanticsLabel,
      child: SizedBox(width: double.infinity, child: body),
    );
  }
}

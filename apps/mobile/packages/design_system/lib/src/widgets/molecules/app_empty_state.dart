import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/widgets/atoms/app_empty_state_icon.dart';
import 'package:design_system/src/widgets/atoms/app_text.dart';
import 'package:flutter/material.dart';

/// Vertical alignment for empty-state content in scrollable shells.
enum AppEmptyStateAlignment {
  center,
  topCenter,
}

/// Canonical empty list / tab placeholder.
///
/// CTA conventions (use [AppButton] factories):
/// - Create / submit / open settings → [AppButton.primary] (full width in lists)
/// - Refresh / passive retry → [AppButton.outlined]
/// - Broaden results (show all) → [AppButton.secondary]
/// - Clear search / filters → [AppButton.text]
/// - Destructive reset → [AppButton.destructive]
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconVariant = AppEmptyStateIconVariant.standard,
    this.iconKey,
    this.animateIconChanges = false,
    this.alignment = AppEmptyStateAlignment.center,
    this.maxWidth,
    this.contentBelowSubtitle,
    this.secondaryAction,
    this.action,
    this.semanticsLabel,
    this.padding,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final AppEmptyStateIconVariant iconVariant;
  final Object? iconKey;
  final bool animateIconChanges;
  final AppEmptyStateAlignment alignment;
  final double? maxWidth;
  final Widget? contentBelowSubtitle;
  final Widget? secondaryAction;
  final Widget? action;
  final String? semanticsLabel;
  final EdgeInsets? padding;

  static const EdgeInsets defaultPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.xxl,
  );

  @override
  Widget build(BuildContext context) {
    final String effectiveSemantics = semanticsLabel ??
        (subtitle != null ? '$title. $subtitle' : title);

    Widget content = Semantics(
      container: true,
      label: effectiveSemantics,
      child: Padding(
        padding: padding ?? defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppEmptyStateIcon(
              icon: icon,
              variant: iconVariant,
              iconKey: iconKey,
              animateIconChanges: animateIconChanges,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppText.emptyTitle(
              title,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              AppText.emptySubtitle(
                subtitle!,
                textAlign: TextAlign.center,
              ),
            ],
            if (contentBelowSubtitle != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              contentBelowSubtitle!,
            ],
            if (secondaryAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              secondaryAction!,
            ],
            if (action != null) ...<Widget>[
              SizedBox(
                height: secondaryAction != null
                    ? AppSpacing.md
                    : AppSpacing.lg,
              ),
              action!,
            ],
          ],
        ),
      ),
    );

    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }

    return Align(
      alignment: alignment == AppEmptyStateAlignment.topCenter
          ? Alignment.topCenter
          : Alignment.center,
      child: content,
    );
  }
}

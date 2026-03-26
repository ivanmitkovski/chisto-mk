import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Grouped, Apple-style sections for the per-step help sheet.
class StageHelpSection {
  const StageHelpSection({this.title, required this.body});

  final String? title;
  final String body;
}

/// Inset grouped-style body: section labels + readable body copy.
class StageHelpFormattedContent extends StatelessWidget {
  const StageHelpFormattedContent({
    super.key,
    required this.sections,
    required this.contextSectionTitle,
    this.extraParagraph,
  });

  final List<StageHelpSection> sections;
  final String contextSectionTitle;
  final String? extraParagraph;

  static const double _sectionGap = AppSpacing.lg;
  static const double _titleBodyGap = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final TextTheme themeText = Theme.of(context).textTheme;
    final TextScaler scaler = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.3,
    );

    final TextStyle titleStyle = (themeText.titleSmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
      height: 1.25,
    );
    final TextStyle bodyStyle = (themeText.bodyMedium ?? const TextStyle()).copyWith(
      color: AppColors.textSecondary,
      height: 1.45,
      letterSpacing: -0.08,
    );

    final List<Widget> children = <Widget>[];

    for (int i = 0; i < sections.length; i++) {
      final StageHelpSection s = sections[i];
      if (i > 0) {
        children.add(const SizedBox(height: _sectionGap));
      }
      final List<Widget> sectionChildren = <Widget>[];
      if (s.title != null && s.title!.isNotEmpty) {
        sectionChildren.add(
          Semantics(
            header: true,
            child: Text(s.title!, style: titleStyle),
          ),
        );
        sectionChildren.add(const SizedBox(height: _titleBodyGap));
      }
      sectionChildren.add(Text(s.body, style: bodyStyle));
      children.add(
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sectionChildren,
          ),
        ),
      );
    }

    if (extraParagraph != null && extraParagraph!.trim().isNotEmpty) {
      children.add(const SizedBox(height: _sectionGap));
      children.add(
        Semantics(
          header: true,
          child: Text(
            contextSectionTitle,
            style: titleStyle,
          ),
        ),
      );
      children.add(const SizedBox(height: _titleBodyGap));
      children.add(Text(extraParagraph!.trim(), style: bodyStyle));
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

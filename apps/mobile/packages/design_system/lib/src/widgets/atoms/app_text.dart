import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Semantic text widget — prefer over raw [Text] in feature presentation code.
///
/// Styles derive from [Theme.of(context).textTheme] (Roboto via [AppTheme]).
/// Use [AppTypography] tokens instead of raw [TextStyle].
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    required this.styleBuilder,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  });

  final String data;
  final TextStyle Function(TextTheme theme) styleBuilder;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final String? semanticsLabel;
  final bool? softWrap;

  /// Large display / nav title (34pt).
  const AppText.display(
    this.data, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _displayStyle;

  /// Screen toolbar title (26pt).
  const AppText.title(
    this.data, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _titleStyle;

  /// Section header in lists and sheets (22pt).
  const AppText.section(
    this.data, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _sectionStyle;

  /// Card or list row primary line (16pt semibold).
  const AppText.cardTitle(
    this.data, {
    super.key,
    this.color,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _cardTitleStyle;

  /// Default body copy (16pt).
  const AppText.body(
    this.data, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _bodyStyle;

  /// Long-form prose with relaxed line height.
  const AppText.bodyProse(
    this.data, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap = true,
  }) : styleBuilder = _bodyProseStyle;

  /// Secondary meta line (14pt muted).
  const AppText.meta(
    this.data, {
    super.key,
    this.color,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _metaStyle;

  /// Caption / timestamp (12pt).
  const AppText.caption(
    this.data, {
    super.key,
    this.color,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _captionStyle;

  /// Form field or grouped section label (13pt).
  const AppText.label(
    this.data, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _labelStyle;

  /// Badge / pill micro label (11pt).
  const AppText.badge(
    this.data, {
    super.key,
    this.color,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _badgeStyle;

  /// Numeric stat with tabular figures.
  const AppText.metric(
    this.data, {
    super.key,
    this.color,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _metricStyle;

  /// Empty state title.
  const AppText.emptyTitle(
    this.data, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.center,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _emptyTitleStyle;

  /// Empty state supporting copy.
  const AppText.emptySubtitle(
    this.data, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.center,
    this.semanticsLabel,
    this.softWrap,
  }) : styleBuilder = _emptySubtitleStyle;

  static TextStyle _displayStyle(TextTheme theme) =>
      theme.displaySmall ?? AppTypography.textTheme.displaySmall!;

  static TextStyle _titleStyle(TextTheme theme) =>
      AppTypography.eventsScreenTitle(theme);

  static TextStyle _sectionStyle(TextTheme theme) =>
      AppTypography.sectionHeader(theme);

  static TextStyle _cardTitleStyle(TextTheme theme) =>
      AppTypography.cardTitle(theme);

  static TextStyle _bodyStyle(TextTheme theme) =>
      (theme.bodyMedium ?? AppTypography.textTheme.bodyMedium!).copyWith(
        color: AppColors.textPrimary,
      );

  static TextStyle _bodyProseStyle(TextTheme theme) =>
      AppTypography.eventsBodyProseRelaxed(theme);

  static TextStyle _metaStyle(TextTheme theme) =>
      AppTypography.cardSubtitle(theme);

  static TextStyle _captionStyle(TextTheme theme) =>
      AppTypography.eventsChatTimestamp(theme);

  static TextStyle _labelStyle(TextTheme theme) =>
      AppTypography.eventsFormFieldLabel(theme);

  static TextStyle _badgeStyle(TextTheme theme) =>
      AppTypography.badgeLabel(theme);

  static TextStyle _metricStyle(TextTheme theme) =>
      AppTypography.eventsMetricValue(theme);

  static TextStyle _emptyTitleStyle(TextTheme theme) =>
      AppTypography.emptyStateTitle(theme);

  static TextStyle _emptySubtitleStyle(TextTheme theme) =>
      AppTypography.emptyStateSubtitle(theme);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    TextStyle style = styleBuilder(textTheme);
    if (color != null) {
      style = style.copyWith(color: color);
    }
    return Text(
      data,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      semanticsLabel: semanticsLabel,
      softWrap: softWrap,
    );
  }
}

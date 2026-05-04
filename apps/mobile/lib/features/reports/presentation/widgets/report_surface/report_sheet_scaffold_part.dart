part of '../report_surface_primitives.dart';

TextStyle _reportSheetSubtitleStyle() {
  final TextStyle? base = AppTypography.textTheme.bodySmall;
  return (base ?? AppTypography.cardSubtitle).copyWith(
    color: AppColors.textMuted,
    height: 1.35,
  );
}

class _ReportSheetHandleFadeIn extends StatefulWidget {
  const _ReportSheetHandleFadeIn();

  @override
  State<_ReportSheetHandleFadeIn> createState() =>
      _ReportSheetHandleFadeInState();
}

class _ReportSheetHandleFadeInState extends State<_ReportSheetHandleFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.fast)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: AppMotion.emphasized,
      ),
      child: const Center(child: _ReportSheetHandle()),
    );
  }
}

ScrollPhysics _reportSheetListPhysics(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.iOS
      ? const BouncingScrollPhysics()
      : const ClampingScrollPhysics();
}

ScrollPhysics _reportSheetUnifiedScrollPhysics(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.iOS
      ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
      : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class ReportSheetScaffold extends StatelessWidget {
  const ReportSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.maxHeightFactor = 0.9,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    this.showHeaderDivider = true,
    this.addBottomInset = true,
    this.headerDividerGap = AppSpacing.md,
    this.fitToContent = false,
    this.useModalRouteShape = false,
    this.scrollChromeWithBody = false,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.subtitleMaxLines,
    this.animateHandleFadeIn = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;
  final double maxHeightFactor;
  final EdgeInsets padding;
  final bool showHeaderDivider;
  final bool addBottomInset;

  /// Vertical space above and below the header rule (smaller feels tighter).
  final double headerDividerGap;

  /// Sheet height follows content until [maxHeightFactor] of the screen, then scrolls.
  final bool fitToContent;

  /// When true, top rounding/shadow are omitted so a parent [showModalBottomSheet]
  /// [shape] can clip the surface without double corners or square overlays.
  final bool useModalRouteShape;

  /// When true, the drag handle, title row, and divider scroll with [child] instead
  /// of staying fixed above a separate scrolling region.
  final bool scrollChromeWithBody;

  /// When set, overrides [AppTypography.sheetTitle] for the sheet title.
  final TextStyle? titleTextStyle;

  /// When set, overrides the default muted subtitle style.
  final TextStyle? subtitleTextStyle;

  /// When set, constrains subtitle lines (e.g. `2` + ellipsis for detail sheets).
  final int? subtitleMaxLines;

  /// Subtle fade-in for the drag handle on first paint (detail modal polish).
  final bool animateHandleFadeIn;

  @override
  Widget build(BuildContext context) {
    final TextStyle resolvedTitleStyle =
        titleTextStyle ?? AppTypography.sheetTitle;
    final TextStyle resolvedSubtitleStyle =
        subtitleTextStyle ?? _reportSheetSubtitleStyle();
    final MediaQueryData media = MediaQuery.of(context);
    final double topPadding = media.padding.top;
    final double bottomPadding = media.padding.bottom;
    final double sheetBottomInset = addBottomInset ? bottomPadding : 0.0;
    final double heightCap = media.size.height * maxHeightFactor;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double parentMax = constraints.maxHeight;
        final double sheetHeight = parentMax.isFinite
            ? (useModalRouteShape
                  ? parentMax.clamp(1.0, double.infinity)
                  : parentMax.clamp(1.0, heightCap))
            : heightCap;

        final BorderRadius sheetRadius = useModalRouteShape
            ? BorderRadius.zero
            : BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusCard),
              );

        final List<BoxShadow> sheetShadow = useModalRouteShape
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 36,
                  offset: const Offset(0, -4),
                ),
              ];

        if (fitToContent) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: sheetRadius,
              boxShadow: sheetShadow,
            ),
            child: ClipRRect(
              borderRadius: sheetRadius,
              clipBehavior: Clip.hardEdge,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: heightCap),
                child: Material(
                  type: MaterialType.transparency,
                  child: ScrollConfiguration(
                    behavior: const NoOverscrollOverlayScrollBehavior(),
                    child: ListView(
                      shrinkWrap: true,
                      physics: _reportSheetListPhysics(context),
                      padding: padding,
                      children: <Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      animateHandleFadeIn
                          ? const _ReportSheetHandleFadeIn()
                          : const Center(child: _ReportSheetHandle()),
                      SizedBox(
                        height: topPadding > 0
                            ? AppSpacing.xs
                            : AppSpacing.radius14,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (leading != null) ...<Widget>[
                            leading!,
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(title, style: resolvedTitleStyle),
                                if (subtitle != null) ...<Widget>[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    subtitle!,
                                    style: resolvedSubtitleStyle,
                                    maxLines: subtitleMaxLines,
                                    overflow: subtitleMaxLines != null
                                        ? TextOverflow.ellipsis
                                        : null,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (trailing != null) ...<Widget>[
                            const SizedBox(width: AppSpacing.sm),
                            trailing!,
                          ],
                        ],
                      ),
                      if (showHeaderDivider) ...<Widget>[
                        SizedBox(height: headerDividerGap),
                        Divider(
                          color: AppColors.divider.withValues(alpha: 0.6),
                          height: 1,
                        ),
                        SizedBox(height: headerDividerGap),
                      ] else
                        const SizedBox(height: AppSpacing.sm),
                      ColoredBox(
                        color: AppColors.panelBackground,
                        child: child,
                      ),
                      if (footer != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        footer!,
                      ],
                      if (addBottomInset) SizedBox(height: sheetBottomInset),
                    ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // DecoratedBox paints the card; hard-edge clip avoids iOS anti-alias seams.
        // Material(type: transparency) supplies a Material ancestor for Text/InkWell
        // (avoids debug yellow underlines) without painting another opaque surface.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: sheetRadius,
            boxShadow: sheetShadow,
          ),
          child: ClipRRect(
            borderRadius: sheetRadius,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              height: sheetHeight,
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: padding,
                    child: scrollChromeWithBody
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Expanded(
                                child: ScrollConfiguration(
                                  behavior:
                                      const NoOverscrollOverlayScrollBehavior(),
                                  child: SingleChildScrollView(
                                    clipBehavior: Clip.none,
                                    physics: _reportSheetUnifiedScrollPhysics(
                                      context,
                                    ),
                                    padding: EdgeInsets.only(
                                      bottom: addBottomInset
                                          ? sheetBottomInset
                                          : MediaQuery.viewPaddingOf(
                                                  context,
                                                ).bottom +
                                                AppSpacing.lg,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const SizedBox(height: AppSpacing.xs),
                                        animateHandleFadeIn
                                            ? const _ReportSheetHandleFadeIn()
                                            : const Center(
                                                child: _ReportSheetHandle(),
                                              ),
                                        SizedBox(
                                          height: topPadding > 0
                                              ? AppSpacing.xs
                                              : AppSpacing.radius14,
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            if (leading != null) ...<Widget>[
                                              leading!,
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                            ],
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    title,
                                                    style: resolvedTitleStyle,
                                                  ),
                                                  if (subtitle !=
                                                      null) ...<Widget>[
                                                    const SizedBox(
                                                      height: AppSpacing.xs,
                                                    ),
                                                    Text(
                                                      subtitle!,
                                                      style:
                                                          resolvedSubtitleStyle,
                                                      maxLines:
                                                          subtitleMaxLines,
                                                      overflow:
                                                          subtitleMaxLines !=
                                                              null
                                                          ? TextOverflow
                                                                .ellipsis
                                                          : null,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (trailing != null) ...<Widget>[
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              trailing!,
                                            ],
                                          ],
                                        ),
                                        if (showHeaderDivider) ...<Widget>[
                                          SizedBox(height: headerDividerGap),
                                          Divider(
                                            color: AppColors.divider.withValues(
                                              alpha: 0.6,
                                            ),
                                            height: 1,
                                          ),
                                          SizedBox(height: headerDividerGap),
                                        ] else
                                          const SizedBox(height: AppSpacing.sm),
                                        ColoredBox(
                                          color: AppColors.panelBackground,
                                          child: child,
                                        ),
                                        if (footer != null) ...<Widget>[
                                          const SizedBox(height: AppSpacing.lg),
                                          footer!,
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: AppSpacing.xs),
                              animateHandleFadeIn
                                  ? const _ReportSheetHandleFadeIn()
                                  : const Center(child: _ReportSheetHandle()),
                              SizedBox(
                                height: topPadding > 0
                                    ? AppSpacing.xs
                                    : AppSpacing.radius14,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (leading != null) ...<Widget>[
                                    leading!,
                                    const SizedBox(width: AppSpacing.sm),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(title, style: resolvedTitleStyle),
                                        if (subtitle != null) ...<Widget>[
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            subtitle!,
                                            style: resolvedSubtitleStyle,
                                            maxLines: subtitleMaxLines,
                                            overflow: subtitleMaxLines != null
                                                ? TextOverflow.ellipsis
                                                : null,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (trailing != null) ...<Widget>[
                                    const SizedBox(width: AppSpacing.sm),
                                    trailing!,
                                  ],
                                ],
                              ),
                              if (showHeaderDivider) ...<Widget>[
                                SizedBox(height: headerDividerGap),
                                Divider(
                                  color: AppColors.divider.withValues(
                                    alpha: 0.6,
                                  ),
                                  height: 1,
                                ),
                                SizedBox(height: headerDividerGap),
                              ] else
                                const SizedBox(height: AppSpacing.sm),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: footer == null
                                        ? sheetBottomInset
                                        : 0,
                                  ),
                                  child: ColoredBox(
                                    color: AppColors.panelBackground,
                                    // [child] is often a ListView with shrinkWrap; without
                                    // [SizedBox.expand] the list only sizes to content and
                                    // the ColoredBox leaves a white band that covers the
                                    // bottom rows visually on modals.
                                    // Default [MaterialScrollBehavior] can paint overscroll
                                    // indicators (white bands) at both edges of nested
                                    // scroll views — match unified-sheet behavior.
                                    child: ScrollConfiguration(
                                      behavior:
                                          const NoOverscrollOverlayScrollBehavior(),
                                      child: SizedBox.expand(child: child),
                                    ),
                                  ),
                                ),
                              ),
                              if (footer != null) ...<Widget>[
                                const SizedBox(height: AppSpacing.lg),
                                footer!,
                              ],
                              if (addBottomInset && footer != null)
                                SizedBox(height: sheetBottomInset),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReportSheetHandle extends StatelessWidget {
  const _ReportSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.sheetHandle,
      height: AppSpacing.sheetHandleHeight,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
    );
  }
}

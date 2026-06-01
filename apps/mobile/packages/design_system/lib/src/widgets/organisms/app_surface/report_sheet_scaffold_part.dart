part of 'app_surface_primitives.dart';

TextStyle _reportSheetSubtitleStyle() {
  final TextStyle? base = AppTypography.textTheme.bodySmall;
  return (base ?? AppTypography.cardSubtitle(AppTypography.textTheme)).copyWith(
    color: AppColors.textMuted,
    height: 1.35,
  );
}

class _AppSheetHandleFadeIn extends StatefulWidget {
  const _AppSheetHandleFadeIn();

  @override
  State<_AppSheetHandleFadeIn> createState() => _AppSheetHandleFadeInState();
}

class _AppSheetHandleFadeInState extends State<_AppSheetHandleFadeIn>
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
      child: const Center(child: _AppSheetHandle()),
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

class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
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
    this.fillAvailableHeight = false,
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

  /// When true, shadow is omitted so a parent [showModalBottomSheet] can own
  /// elevation; the surface still uses [AppSpacing.radiusSheet] so transparent
  /// route backgrounds clip correctly.
  final bool useModalRouteShape;

  /// When true, the drag handle, title row, and divider scroll with [child] instead
  /// of staying fixed above a separate scrolling region.
  final bool scrollChromeWithBody;

  /// When set, overrides [AppTypography.sheetTitle(textTheme)] for the sheet title.
  final TextStyle? titleTextStyle;

  /// When set, overrides the default muted subtitle style.
  final TextStyle? subtitleTextStyle;

  /// When set, constrains subtitle lines (e.g. `2` + ellipsis for detail sheets).
  final int? subtitleMaxLines;

  /// Subtle fade-in for the drag handle on first paint (detail modal polish).
  final bool animateHandleFadeIn;

  /// When true, the sheet expands to [maxHeightFactor] instead of hugging content.
  /// Use for scrollable filter panels so toggling rows does not resize the modal.
  final bool fillAvailableHeight;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle resolvedTitleStyle =
        titleTextStyle ?? AppTypography.sheetTitle(textTheme);
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
        final double maxSheetHeight = parentMax.isFinite
            ? math.min(parentMax, heightCap)
            : heightCap;

        final BorderRadius sheetRadius = useModalRouteShape
            ? const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusSheet),
              )
            : const BorderRadius.vertical(
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
                        if (animateHandleFadeIn)
                          const _AppSheetHandleFadeIn()
                        else
                          const Center(child: _AppSheetHandle()),
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
                        child,
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxSheetHeight,
                minHeight: fillAvailableHeight ? maxSheetHeight : 0,
              ),
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
                            mainAxisSize: fillAvailableHeight
                                ? MainAxisSize.max
                                : MainAxisSize.min,
                            children: <Widget>[
                              if (fillAvailableHeight)
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
                                          if (animateHandleFadeIn)
                                            const _AppSheetHandleFadeIn()
                                          else
                                            const Center(
                                              child: _AppSheetHandle(),
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
                                              color: AppColors.divider
                                                  .withValues(alpha: 0.6),
                                              height: 1,
                                            ),
                                            SizedBox(height: headerDividerGap),
                                          ] else
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                          child,
                                          if (footer != null) ...<Widget>[
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            footer!,
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Flexible(
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
                                          if (animateHandleFadeIn)
                                            const _AppSheetHandleFadeIn()
                                          else
                                            const Center(
                                              child: _AppSheetHandle(),
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
                                              color: AppColors.divider
                                                  .withValues(alpha: 0.6),
                                              height: 1,
                                            ),
                                            SizedBox(height: headerDividerGap),
                                          ] else
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                          child,
                                          if (footer != null) ...<Widget>[
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
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
                            mainAxisSize: fillAvailableHeight
                                ? MainAxisSize.max
                                : MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: AppSpacing.xs),
                              if (animateHandleFadeIn)
                                const _AppSheetHandleFadeIn()
                              else
                                const Center(child: _AppSheetHandle()),
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
                              if (fillAvailableHeight)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: footer == null
                                          ? sheetBottomInset
                                          : 0,
                                    ),
                                    child: ScrollConfiguration(
                                      behavior:
                                          const NoOverscrollOverlayScrollBehavior(),
                                      child: child,
                                    ),
                                  ),
                                )
                              else
                                Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: footer == null
                                          ? sheetBottomInset
                                          : 0,
                                    ),
                                    child: ScrollConfiguration(
                                      behavior:
                                          const NoOverscrollOverlayScrollBehavior(),
                                      child: child,
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

class _AppSheetHandle extends StatelessWidget {
  const _AppSheetHandle();

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

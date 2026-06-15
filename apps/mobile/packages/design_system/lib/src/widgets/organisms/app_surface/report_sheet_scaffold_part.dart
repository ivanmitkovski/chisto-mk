part of 'app_surface_primitives.dart';

TextStyle _reportSheetSubtitleStyle() {
  final TextStyle? base = AppTypography.textTheme.bodySmall;
  return (base ?? AppTypography.cardSubtitle(AppTypography.textTheme)).copyWith(
    color: AppColors.textMuted,
    height: 1.35,
  );
}

class _AppSheetHandleFadeIn extends StatefulWidget {
  const _AppSheetHandleFadeIn({this.semanticLabel});

  final String? semanticLabel;

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
      child: Center(
        child: _AppSheetHandle(semanticLabel: widget.semanticLabel),
      ),
    );
  }
}

ScrollPhysics _reportSheetListPhysics(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.iOS
      ? const BouncingScrollPhysics()
      : const ClampingScrollPhysics();
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
    @Deprecated(
      'Header chrome is always fixed above the scroll body. Remove this flag.',
    )
    this.scrollChromeWithBody = false,
    this.dragHandleSemanticLabel,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.subtitleMaxLines,
    this.animateHandleFadeIn = false,
    this.fillAvailableHeight = false,
    this.boundedScrollBody = false,
    this.padFooterForKeyboard = false,
    this.shrinkForKeyboard = true,
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

  @Deprecated(
    'Header chrome is always fixed above the scroll body. Remove this flag.',
  )
  final bool scrollChromeWithBody;

  /// TalkBack / VoiceOver label for the drag handle dismiss affordance.
  final String? dragHandleSemanticLabel;

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

  /// When true, the scroll body hugs short content but scrolls within the remaining
  /// height budget (header + footer pinned). Use for keyboard-lifted form sheets.
  final bool boundedScrollBody;

  /// When true, lifts [footer] above the keyboard via [MediaQuery.viewInsets].
  /// Use with overlay modal hosts that keep sheet height stable.
  final bool padFooterForKeyboard;

  /// When false, the sheet keeps [restingCap] height while the keyboard is open.
  /// Use with overlay pinned-footers that stay at the screen bottom behind the IME.
  final bool shrinkForKeyboard;

  Widget? _resolvedFooter(BuildContext context) {
    final Widget? bar = footer;
    if (bar == null) {
      return null;
    }
    final double keyboardInset = padFooterForKeyboard
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0;
    // Home-indicator footer padding stacks on top of the keyboard and reads as
    // a white band above the IME in overlay-model sheets (see [_homeIndicatorInset]).
    final double homeInset = addBottomInset && keyboardInset == 0
        ? MediaQuery.viewPaddingOf(context).bottom
        : 0;
    if (homeInset <= 0) {
      return bar;
    }
    return Padding(
      padding: EdgeInsets.only(bottom: homeInset),
      child: bar,
    );
  }

  Widget _wrapKeyboardLift(BuildContext context, Widget sheet) {
    if (!padFooterForKeyboard) {
      return sheet;
    }
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset <= 0) {
      return sheet;
    }
    // Lift the whole panel above the IME; padding sits outside the painted sheet
    // so footer CTAs stay flush without an internal white band (overlay sheets).
    return AnimatedPadding(
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: sheet,
    );
  }

  double _homeIndicatorInset(BuildContext context) {
    if (!addBottomInset) {
      return 0;
    }
    // Home-indicator scroll padding stacks on top of the keyboard and reads as
    // a white band above the IME in overlay-model sheets.
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset > 0) {
      return 0;
    }
    return MediaQuery.viewPaddingOf(context).bottom;
  }

  Widget _scrollBody(BuildContext context) {
    final double scrollBottom =
        footer == null ? _homeIndicatorInset(context) : 0;
    return ScrollConfiguration(
      behavior: const NoOverscrollOverlayScrollBehavior(),
      child: AppSheetScrollInset.wrap(
        bottom: scrollBottom,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget? resolvedFooter = _resolvedFooter(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle resolvedTitleStyle =
        titleTextStyle ?? AppTypography.sheetTitle(textTheme);
    final TextStyle resolvedSubtitleStyle =
        subtitleTextStyle ?? _reportSheetSubtitleStyle();
    final MediaQueryData viewMq = MediaQueryData.fromView(View.of(context));
    final double topInset = appSheetViewportTopInset(context);
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double viewHeight = viewMq.size.height;
    final double restingCap = (viewHeight - topInset) * maxHeightFactor;
    final double keyboardSlotCap = viewHeight - topInset - keyboardInset;
    final double heightCap = keyboardInset > 0 && shrinkForKeyboard
        ? math.min(restingCap, keyboardSlotCap)
        : restingCap;
    final double homeIndicatorInset = _homeIndicatorInset(context);
    final double headerTopGap =
        topInset > 0 ? AppSpacing.xs : AppSpacing.radius14;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double parentMax = constraints.maxHeight;
        final double maxSheetHeight = parentMax.isFinite
            ? math.min(parentMax, heightCap)
            : heightCap;
        final double minSheetHeight =
            fillAvailableHeight ? maxSheetHeight : 0;

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
          return _wrapKeyboardLift(
            context,
            DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: sheetRadius,
              boxShadow: sheetShadow,
            ),
            child: ClipRRect(
              borderRadius: sheetRadius,
              clipBehavior: Clip.hardEdge,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                child: Material(
                  type: MaterialType.transparency,
                  child: ScrollConfiguration(
                    behavior: const NoOverscrollOverlayScrollBehavior(),
                    child: SingleChildScrollView(
                      physics: _reportSheetListPhysics(context),
                      padding: footer == null && addBottomInset
                          ? padding.copyWith(
                              bottom: padding.bottom + homeIndicatorInset,
                            )
                          : padding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          if (animateHandleFadeIn)
                            _AppSheetHandleFadeIn(
                              semanticLabel: dragHandleSemanticLabel,
                            )
                          else
                            Center(
                              child: _AppSheetHandle(
                                semanticLabel: dragHandleSemanticLabel,
                              ),
                            ),
                          SizedBox(
                            height: headerTopGap,
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
                          if (resolvedFooter != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.lg),
                            resolvedFooter,
                          ],
                        ],
                      ),
                    ),
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
        return _wrapKeyboardLift(
          context,
          DecoratedBox(
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
                minHeight: minSheetHeight,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: padding,
                    child: Column(
                      mainAxisSize: fillAvailableHeight
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        if (animateHandleFadeIn)
                          _AppSheetHandleFadeIn(
                            semanticLabel: dragHandleSemanticLabel,
                          )
                        else
                          Center(
                            child: _AppSheetHandle(
                              semanticLabel: dragHandleSemanticLabel,
                            ),
                          ),
                        SizedBox(
                          height: headerTopGap,
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
                            color: AppColors.divider.withValues(
                              alpha: 0.6,
                            ),
                            height: 1,
                          ),
                          SizedBox(height: headerDividerGap),
                        ] else
                          const SizedBox(height: AppSpacing.sm),
                        if (fillAvailableHeight)
                          Expanded(child: _scrollBody(context))
                        else if (boundedScrollBody)
                          _scrollBody(context)
                        else
                          Flexible(
                            fit: FlexFit.loose,
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: 1,
                              child: _scrollBody(context),
                            ),
                          ),
                        if (resolvedFooter != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.lg),
                          resolvedFooter,
                        ],
                      ],
                    ),
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
  const _AppSheetHandle({this.semanticLabel});

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: AppSpacing.sheetHandle,
        height: AppSpacing.sheetHandleHeight,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ),
    );
  }
}

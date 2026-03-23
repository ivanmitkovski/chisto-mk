import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/comments_bottom_sheet.dart';
import 'package:chisto_mobile/features/home/domain/models/take_action_type.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/take_action_coordinator.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/take_action_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:chisto_mobile/shared/widgets/immersive_photo_gallery.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_card_widgets.dart';

class PollutionSiteCard extends StatefulWidget {
  const PollutionSiteCard({super.key, required this.site});

  final PollutionSite site;

  @override
  State<PollutionSiteCard> createState() => _PollutionSiteCardState();
}

class _PollutionSiteCardState extends State<PollutionSiteCard> {
  late bool _isUpvoted;
  late int _upvoteCount;
  late int _commentCount;
  late int _shareCount;
  late List<Comment> _sessionComments;
  bool _isSaved = false;
  double _saveIconScale = 1.0;
  bool _didPrefetchImages = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // Cache for word-boundary truncation to avoid recomputing every build.
  String? _cachedTitleTruncated;
  String? _cachedDescTruncated;
  double? _cachedTruncationWidth;
  String? _cachedTitleKey;
  String? _cachedDescKey;

  static const double _cardRadius = AppSpacing.radiusXl;
  static const double _counterMinWidth = 28.0;
  static const double _actionIconSize = 24.0;
  static const double _actionCountFontSize = 13.0;

  PollutionSite get site => widget.site;

  @override
  void initState() {
    super.initState();
    _isUpvoted = false;
    _upvoteCount = site.score;
    _commentCount = site.commentCount;
    _shareCount = (site.participantCount / 2).ceil();
    _sessionComments = List<Comment>.from(site.comments);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefetchImages) return;
    _didPrefetchImages = true;
    final List<ImageProvider> images = site.galleryImages;
    for (int i = 0; i < images.length && i < 3; i++) {
      precacheImage(images[i], context);
    }
  }

  void _onUpvoteTap() {
    AppHaptics.tap();
    setState(() {
      if (_isUpvoted) {
        _isUpvoted = false;
        _upvoteCount = (_upvoteCount - 1).clamp(0, 9999);
      } else {
        _isUpvoted = true;
        _upvoteCount += 1;
      }
    });
  }

  void _toggleSave() {
    AppHaptics.light();
    setState(() {
      _isSaved = !_isSaved;
      _saveIconScale = 0.9;
    });

    Future<void>.delayed(AppMotion.xFast, () {
      if (!mounted) return;
      setState(() => _saveIconScale = 1.0);
    });

    final String message = _isSaved
        ? 'You will get updates for this site'
        : 'Removed from your saved sites';
    AppSnack.show(
      context,
      message: message,
      type: _isSaved ? AppSnackType.success : AppSnackType.info,
      duration: const Duration(milliseconds: 1200),
    );
  }

  Widget _buildAnimatedCount(int value, TextStyle style) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text('$value', key: ValueKey<int>(value), style: style),
    );
  }

  /// Truncates [text] at a word boundary so the ellipsis does not cut words in the middle.
  static String _truncateAtWordBoundary(
    String text, {
    required TextStyle style,
    required double maxWidth,
    required int maxLines,
  }) {
    if (text.isEmpty) return text;
    const String ellipsis = '…';
    final TextSpan ellipsisSpan = TextSpan(text: ellipsis, style: style);
    final TextPainter ellipsisPainter = TextPainter(
      text: ellipsisSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    final double ellipsisWidth = ellipsisPainter.width;
    final double availableWidth = (maxWidth - ellipsisWidth).clamp(
      1.0,
      double.infinity,
    );
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableWidth);
    if (!painter.didExceedMaxLines) return text;
    final Offset endOffset = Offset(availableWidth, painter.size.height - 1);
    final TextPosition position = painter.getPositionForOffset(endOffset);
    final int offset = position.offset.clamp(0, text.length);
    final int lastSpace = offset > 0 ? text.lastIndexOf(' ', offset - 1) : -1;
    if (lastSpace > 0) {
      return '${text.substring(0, lastSpace).trimRight()}$ellipsis';
    }
    return '${text.substring(0, offset).trimRight()}$ellipsis';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: false,
      label: 'Pollution site: ${site.title}. Tap to open details.',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: AppSpacing.md,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: AppSpacing.lg,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: () => _openDetails(context),
              splashColor: AppColors.primary.withValues(alpha: 0.08),
              highlightColor: AppColors.black.withValues(alpha: 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildImage(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildEngagementRow(context),
                        const SizedBox(height: AppSpacing.md),
                        LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final double maxWidth = constraints.maxWidth;
                                final TextStyle titleStyle =
                                    AppTypography.textTheme.titleMedium!;
                                final TextStyle descStyle = AppTypography
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                      fontSize: 15,
                                    );
                                final bool cacheValid =
                                    _cachedTruncationWidth == maxWidth &&
                                    _cachedTitleKey == site.title &&
                                    _cachedDescKey == site.description &&
                                    _cachedTitleTruncated != null &&
                                    _cachedDescTruncated != null;
                                String titleDisplay;
                                String descDisplay;
                                if (cacheValid) {
                                  titleDisplay = _cachedTitleTruncated!;
                                  descDisplay = _cachedDescTruncated!;
                                } else {
                                  titleDisplay = _truncateAtWordBoundary(
                                    site.title,
                                    style: titleStyle,
                                    maxWidth: maxWidth,
                                    maxLines: 1,
                                  );
                                  descDisplay = _truncateAtWordBoundary(
                                    site.description,
                                    style: descStyle,
                                    maxWidth: maxWidth,
                                    maxLines: 2,
                                  );
                                  _cachedTitleTruncated = titleDisplay;
                                  _cachedDescTruncated = descDisplay;
                                  _cachedTitleKey = site.title;
                                  _cachedDescKey = site.description;
                                  _cachedTruncationWidth = maxWidth;
                                }
                                final String titleNorm =
                                    site.title.trim().toLowerCase();
                                final String descNorm =
                                    site.description.trim().toLowerCase();
                                final bool redundant =
                                    titleNorm.isEmpty ||
                                    descNorm.isEmpty ||
                                    titleNorm == descNorm ||
                                    descNorm.startsWith(titleNorm) ||
                                    titleNorm.startsWith(descNorm);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    SizedBox(
                                      width: maxWidth,
                                      child: Text(
                                        titleDisplay,
                                        style: titleStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!redundant) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      SizedBox(
                                        width: maxWidth,
                                        child: Text(
                                          descDisplay,
                                          style: descStyle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(
                          label: 'Take action',
                          onPressed: () => _openTakeActionSheet(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final List<ImageProvider> images = site.galleryImages;

    return Semantics(
      image: true,
      label: 'Photo of pollution site',
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (int index) {
                setState(() {
                  _currentImageIndex = index;
                });
                _prefetchAround(index, images);
              },
              physics: const BouncingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return SizedBox.expand(
                  child: AppSmartImage(image: images[index]),
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.black.withValues(alpha: 0.28),
                        AppColors.transparent,
                        AppColors.black.withValues(alpha: 0.2),
                      ],
                      stops: const <double>[0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: GalleryGlassPill(
                emphasis: GalleryGlassPillEmphasis.strong,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: site.statusColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${site.statusLabel} • ${site.distanceKm.toStringAsFixed(0)} km',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: AppSpacing.sm,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 52,
                    child: Center(
                      child: GalleryPageIndicators(
                        currentIndex: _currentImageIndex,
                        totalCount: images.length,
                        maxVisible: 4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _prefetchAround(int index, List<ImageProvider> images) {
    final int previous = index - 1;
    final int next = index + 1;
    if (previous >= 0 && previous < images.length) {
      precacheImage(images[previous], context);
    }
    if (next >= 0 && next < images.length) {
      precacheImage(images[next], context);
    }
  }

  Widget _buildEngagementRow(BuildContext context) {
    final TextStyle countStyle = Theme.of(context).textTheme.bodySmall!
        .copyWith(
          fontSize: _actionCountFontSize,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        );
    final int commentCount = _commentCount;
    final int shareCount = _shareCount;

    return Row(
      children: <Widget>[
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Semantics(
                        button: true,
                        label: _isUpvoted ? 'Remove upvote' : 'Upvote',
                        child: GestureDetector(
                          onTap: _onUpvoteTap,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: SvgPicture.asset(
                                AppAssets.cardArrowUp,
                                width: _actionIconSize,
                                height: _actionIconSize,
                                colorFilter: ColorFilter.mode(
                                  _isUpvoted
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        button: true,
                        label: '$_upvoteCount upvotes, tap to see who',
                        child: GestureDetector(
                          onTap: () async {
                            AppHaptics.tap();
                            await _showUpvotersSheet(context);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: _counterMinWidth,
                            height: 44,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildAnimatedCount(
                                _upvoteCount,
                                countStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Semantics(
                  button: true,
                  label: 'Comments, $commentCount',
                  child: GestureDetector(
                    onTap: () {
                      AppHaptics.tap();
                      _openCommentsSheet(context);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: SvgPicture.asset(
                                AppAssets.cardComments,
                                width: _actionIconSize,
                                height: _actionIconSize,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.textPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: _counterMinWidth,
                            height: 44,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildAnimatedCount(
                                commentCount,
                                countStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Semantics(
                  button: true,
                  label: 'Shares, $shareCount',
                  child: GestureDetector(
                    onTap: () {
                      AppHaptics.tap();
                      _openShareSheet(context);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: SvgPicture.asset(
                                AppAssets.cardShare,
                                width: _actionIconSize,
                                height: _actionIconSize,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.textPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: _counterMinWidth,
                            height: 44,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildAnimatedCount(
                                shareCount,
                                countStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          label: _isSaved ? 'Unsave, stop updates' : 'Save and get updates',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _toggleSave();
            },
            child: SizedBox(
              width: 44,
              height: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: AppMotion.emphasized,
                  scale: _saveIconScale,
                  child: Icon(
                    _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: _actionIconSize,
                    color: _isSaved
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openDetails(BuildContext context) {
    AppHaptics.softTransition();
    for (int i = 0; i < site.galleryImages.length && i < 3; i++) {
      precacheImage(site.galleryImages[i], context);
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PollutionSiteDetailScreen(site: site),
      ),
    );
  }

  Future<void> _openCommentsSheet(BuildContext context) async {
    final DraggableScrollableController sheetController =
        DraggableScrollableController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      useSafeArea: true,
      barrierColor: AppColors.overlay,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        if (keyboardOpen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!sheetController.isAttached) return;
            if (sheetController.size >= 0.94) return;
            sheetController.animateTo(
              0.95,
              duration: AppMotion.medium,
              curve: AppMotion.emphasized,
            );
          });
        }
        return DraggableScrollableSheet(
          controller: sheetController,
          expand: false,
          initialChildSize: keyboardOpen ? 0.95 : 0.74,
          minChildSize: keyboardOpen ? 0.95 : 0.56,
          maxChildSize: 0.95,
          snap: !keyboardOpen,
          snapSizes: keyboardOpen ? null : const <double>[0.74, 0.95],
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.panelBackground,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusPill)),
              ),
              clipBehavior: Clip.antiAlias,
              child: CommentsBottomSheet(
                comments: _sessionComments,
                siteTitle: site.title,
                scrollController: scrollController,
                onCommentsCountChanged: (int count) {
                  if (!mounted) return;
                  setState(() => _commentCount = count);
                },
                onCommentsChanged: (List<Comment> comments) {
                  if (!mounted) return;
                  setState(() => _sessionComments = comments);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openTakeActionSheet(BuildContext context) async {
    final TakeActionType? action = await TakeActionSheet.show(context);
    if (action == null || !context.mounted) return;
    await TakeActionCoordinator.execute(
      context,
      action: action,
      site: site,
      isFromSiteDetail: false,
      onShareCountChanged: () {
        if (mounted) setState(() => _shareCount = (_shareCount + 1).clamp(0, 9999));
      },
    );
  }

  Future<void> _openShareSheet(BuildContext context) async {
    await TakeActionCoordinator.execute(
      context,
      action: TakeActionType.shareSite,
      site: site,
      isFromSiteDetail: false,
      onShareCountChanged: () {
        if (mounted) setState(() => _shareCount = (_shareCount + 1).clamp(0, 9999));
      },
    );
  }

  Future<void> _showUpvotersSheet(BuildContext context) async {
    final int count = _upvoteCount.clamp(0, 999);
    if (count == 0) {
      AppSnack.show(
        context,
        message: 'No upvotes yet. Be the first to support this site!',
        type: AppSnackType.info,
      );
      return;
    }

    final List<String> names = List<String>.generate(
      count,
      (int index) => 'Eco volunteer ${index + 1}',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      useSafeArea: true,
      barrierColor: AppColors.overlay,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const <double>[0.68, 0.95],
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.panelBackground,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusPill)),
              ),
              clipBehavior: Clip.antiAlias,
              child: UpvotersSheetContent(
                count: count,
                names: names,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }
}


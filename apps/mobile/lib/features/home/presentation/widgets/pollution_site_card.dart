import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
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
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/cache/site_image_prefetch_queue.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';

class PollutionSiteCard extends StatefulWidget {
  const PollutionSiteCard({
    super.key,
    required this.site,
    this.feedSessionId,
    this.onHidden,
  });

  final PollutionSite site;
  final String? feedSessionId;
  final ValueChanged<String>? onHidden;

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
  bool _isCardVisible = true;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isUpvoteInFlight = false;
  bool _isSaveInFlight = false;
  bool _isShareInFlight = false;
  double _upvoteIconScale = 1;
  final DateTime _openedAt = DateTime.now();
  bool _impressionTracked = false;
  Timer? _impressionTimer;

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
    _syncFromSite();
  }

  @override
  void dispose() {
    _impressionTimer?.cancel();
    final int dwellSeconds = DateTime.now().difference(_openedAt).inSeconds;
    if (_impressionTracked && dwellSeconds >= 2) {
      _trackFeedEvent(
        'dwell_bucket',
        metadata: <String, dynamic>{
          'bucket': _dwellBucketForSeconds(dwellSeconds),
        },
      );
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PollutionSiteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool changedSite = oldWidget.site.id != widget.site.id;
    final bool changedEngagement =
        oldWidget.site.score != widget.site.score ||
        oldWidget.site.commentCount != widget.site.commentCount ||
        oldWidget.site.shareCount != widget.site.shareCount ||
        oldWidget.site.isUpvotedByMe != widget.site.isUpvotedByMe ||
        oldWidget.site.isSavedByMe != widget.site.isSavedByMe;
    if (changedSite || changedEngagement) {
      _syncFromSite();
      if (changedSite) {
        _impressionTracked = false;
        _impressionTimer?.cancel();
        _impressionTimer = null;
      }
    }
  }

  void _syncFromSite() {
    _isUpvoted = site.isUpvotedByMe;
    _upvoteCount = site.score;
    _commentCount = site.commentCount;
    _shareCount = site.shareCount;
    _sessionComments = List<Comment>.from(site.comments);
    _isSaved = site.isSavedByMe;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefetchImages) return;
    _didPrefetchImages = true;
    final List<ImageProvider> images = site.galleryImages;
    SiteImagePrefetchQueue.instance.prefetchList(
      context,
      images,
      maxItems: 3,
      shouldPrefetch: () => mounted,
    );
  }

  void _onUpvoteTap() {
    if (_isUpvoteInFlight) return;
    _isUpvoteInFlight = true;
    final bool prevUpvoted = _isUpvoted;
    final int prevCount = _upvoteCount;
    setState(() {
      if (_isUpvoted) {
        _isUpvoted = false;
        _upvoteCount = (_upvoteCount - 1).clamp(0, 9999);
      } else {
        _isUpvoted = true;
        _upvoteCount += 1;
      }
      _upvoteIconScale = 0.86;
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _upvoteIconScale = 1);
    });
    final repo = ServiceLocator.instance.sitesRepository;
    final future = prevUpvoted
        ? repo.removeSiteUpvote(site.id)
        : repo.upvoteSite(site.id);
    future
        .then((snapshot) {
          if (!mounted) return;
          setState(() {
            _isUpvoted = snapshot.isUpvotedByMe;
            _upvoteCount = snapshot.upvotesCount;
            _commentCount = snapshot.commentsCount;
            _shareCount = snapshot.sharesCount;
            _isSaved = snapshot.isSavedByMe;
          });
          AppHaptics.light();
          _trackFeedEvent('upvote');
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() {
            _isUpvoted = prevUpvoted;
            _upvoteCount = prevCount;
          });
          AppHaptics.medium();
          AppSnack.show(
            context,
            message: context.l10n.siteCardUpvoteFailedSnack,
            type: AppSnackType.warning,
          );
        })
        .whenComplete(() {
          _isUpvoteInFlight = false;
        });
  }

  Future<void> _toggleSave() async {
    if (_isSaveInFlight) return;
    _isSaveInFlight = true;
    AppHaptics.light();
    final bool nextSaved = !_isSaved;
    setState(() {
      _isSaved = nextSaved;
      _saveIconScale = 0.9;
    });

    Future<void>.delayed(AppMotion.xFast, () {
      if (!mounted) return;
      setState(() => _saveIconScale = 1.0);
    });

    final String message = nextSaved
        ? 'You will get updates for this site'
        : 'Removed from your saved sites';
    AppSnack.show(
      context,
      message: message,
      type: nextSaved ? AppSnackType.success : AppSnackType.info,
      duration: const Duration(milliseconds: 1200),
    );
    try {
      final repo = ServiceLocator.instance.sitesRepository;
      final snapshot = nextSaved
          ? await repo.saveSite(site.id)
          : await repo.unsaveSite(site.id);
      if (!mounted) return;
      setState(() {
        _isSaved = snapshot.isSavedByMe;
        _upvoteCount = snapshot.upvotesCount;
        _commentCount = snapshot.commentsCount;
        _shareCount = snapshot.sharesCount;
        _isUpvoted = snapshot.isUpvotedByMe;
      });
      _trackFeedEvent(
        'save',
        metadata: <String, dynamic>{'saved': snapshot.isSavedByMe},
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaved = !nextSaved);
        AppSnack.show(
          context,
          message: context.l10n.siteCardSavedFailedSnack,
          type: AppSnackType.warning,
        );
      }
    } finally {
      _isSaveInFlight = false;
    }
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
    return VisibilityDetector(
      key: ValueKey<String>('feed-card-${site.id}'),
      onVisibilityChanged: (VisibilityInfo info) {
        _isCardVisible = info.visibleFraction > 0.14;
        if (_impressionTracked) return;
        if (info.visibleFraction < 0.5) {
          _impressionTimer?.cancel();
          _impressionTimer = null;
          return;
        }
        _impressionTimer ??= Timer(const Duration(milliseconds: 500), () {
          if (!mounted || _impressionTracked) return;
          _trackFeedEvent('impression');
          _impressionTracked = true;
          _impressionTimer = null;
        });
      },
      child: Semantics(
        button: false,
        label: context.l10n.siteCardPollutionSiteSemantic(site.title),
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
                          const SizedBox(height: AppSpacing.sm),
                          LayoutBuilder(
                            builder:
                                (
                                  BuildContext context,
                                  BoxConstraints constraints,
                                ) {
                                  final double maxWidth = constraints.maxWidth;
                                  final TextStyle titleStyle = AppTypography
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        letterSpacing: -0.2,
                                      );
                                  final TextStyle descStyle = AppTypography
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                        fontSize: 14,
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
                                  final String titleNorm = site.title
                                      .trim()
                                      .toLowerCase();
                                  final String descNorm = site.description
                                      .trim()
                                      .toLowerCase();
                                  final bool redundant =
                                      titleNorm.isEmpty ||
                                      descNorm.isEmpty ||
                                      titleNorm == descNorm;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                          const SizedBox(height: AppSpacing.md),
                          PrimaryButton(
                            label: context.l10n.siteCardTakeActionSemantic,
                            onPressed: () => _openTakeActionSheet(),
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
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final List<ImageProvider> images = site.galleryImages;

    return Semantics(
      image: true,
      label: context.l10n.siteCardPhotoSemantic(site.title),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (int index) {
                AppHaptics.light();
                setState(() {
                  _currentImageIndex = index;
                });
                _prefetchAround(index, images);
              },
              physics: const BouncingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return SizedBox.expand(
                  child: AppSmartImage(
                    image: images[index],
                    semanticLabel: 'Photo ${index + 1} of ${site.title}',
                    decodePreset: AppSmartImageDecodePreset.feed,
                  ),
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
                      site.distanceKm >= 0
                          ? '${site.statusLabel} • ${_formatDistance(site.distanceKm)}'
                          : site.statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Semantics(
                button: true,
                label: context.l10n.siteCardFeedOptionsSemantic,
                child: InkWell(
                  onTap: _openFeedbackSheet,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textOnDark,
                      size: 20,
                    ),
                  ),
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
    SiteImagePrefetchQueue.instance.prefetchAround(
      context,
      images,
      index,
      shouldPrefetch: () => mounted && _isCardVisible,
    );
  }

  Widget _buildEngagementRow(BuildContext context) {
    final TextStyle countStyle = Theme.of(context).textTheme.bodySmall!
        .copyWith(
          fontSize: _actionCountFontSize,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
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
                        label: _isUpvoted
                            ? 'Remove upvote for ${site.title}'
                            : 'Upvote ${site.title}',
                        child: GestureDetector(
                          onTap: _isUpvoteInFlight ? null : _onUpvoteTap,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 180),
                                curve: AppMotion.emphasized,
                                scale: _upvoteIconScale,
                                child: Icon(
                                  _isUpvoted
                                      ? Icons.arrow_circle_up_rounded
                                      : Icons.arrow_circle_up_outlined,
                                  size: _actionIconSize,
                                  color: _isUpvoted
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        button: true,
                        label:
                            '$_upvoteCount ${_upvoteCount == 1 ? 'upvote' : 'upvotes'} on ${site.title}, tap to see supporters',
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
                  label:
                      '$commentCount ${commentCount == 1 ? 'comment' : 'comments'} on ${site.title}',
                  child: GestureDetector(
                    onTap: () {
                      AppHaptics.tap();
                      _openCommentsSheet();
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
                              child: Icon(
                                Icons.mode_comment_outlined,
                                size: _actionIconSize,
                                color: AppColors.textPrimary,
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
                  label:
                      '$shareCount ${shareCount == 1 ? 'share' : 'shares'} on ${site.title}',
                  child: GestureDetector(
                    onTap: _isShareInFlight
                        ? null
                        : () {
                            AppHaptics.tap();
                            _openShareSheet();
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
                                colorFilter: ColorFilter.mode(
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
          label: _isSaved
              ? 'Unsave ${site.title} and stop updates'
              : 'Save ${site.title} and get updates',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isSaveInFlight ? null : () => _toggleSave(),
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
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    AppHaptics.softTransition();
    _trackFeedEvent('detail_open');
    SiteImagePrefetchQueue.instance.prefetchList(
      context,
      site.galleryImages,
      maxItems: 3,
      shouldPrefetch: () => mounted,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PollutionSiteDetailScreen(site: site),
      ),
    );
    if (!mounted) return;
    try {
      final refreshed = await ServiceLocator.instance.sitesRepository
          .getSiteById(site.id);
      if (!mounted || refreshed == null) return;
      setState(() {
        _isUpvoted = refreshed.isUpvotedByMe;
        _isSaved = refreshed.isSavedByMe;
        _upvoteCount = refreshed.score;
        _commentCount = refreshed.commentCount;
        _shareCount = refreshed.shareCount;
      });
    } catch (_) {}
  }

  Future<void> _openCommentsSheet() async {
    _trackFeedEvent('comment_open');
    Future<List<Comment>> loadComments(String sort) async {
      final result = await ServiceLocator.instance.sitesRepository
          .getSiteComments(site.id, sort: sort);
      if (mounted) {
        setState(() => _commentCount = result.total);
      }
      return result.items.map(_commentFromSiteCommentItem).toList();
    }

    try {
      final comments = await loadComments('top');
      if (mounted) {
        setState(() {
          _sessionComments = comments;
        });
      }
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.siteCardCommentsLoadFailedSnack,
          type: AppSnackType.warning,
        );
      }
    }
    if (!mounted) return;
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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusPill),
                ),
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
                onCommentSubmitted: (String text, String? parentId) {
                  return ServiceLocator.instance.sitesRepository
                      .createSiteComment(site.id, text, parentId: parentId)
                      .then(_commentFromSiteCommentItem);
                },
                onCommentEdited: (String commentId, String body) {
                  return ServiceLocator.instance.sitesRepository
                      .updateSiteComment(site.id, commentId, body);
                },
                onCommentDeleted: (String commentId) {
                  return ServiceLocator.instance.sitesRepository
                      .deleteSiteComment(site.id, commentId);
                },
                onCommentLikeToggled: (String commentId, bool shouldLike) {
                  return shouldLike
                      ? ServiceLocator.instance.sitesRepository
                            .likeSiteComment(site.id, commentId)
                            .then((_) {})
                      : ServiceLocator.instance.sitesRepository
                            .unlikeSiteComment(site.id, commentId)
                            .then((_) {});
                },
                onSortChanged: loadComments,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openTakeActionSheet() async {
    if (_isShareInFlight) return;
    final TakeActionType? action = await TakeActionSheet.show(context);
    if (action == null || !mounted) return;
    final bool shareConfirmed = await TakeActionCoordinator.execute(
      context,
      action: action,
      site: site,
      isFromSiteDetail: false,
      onShareCountChanged: () {
        if (mounted) {
          setState(() => _shareCount = (_shareCount + 1).clamp(0, 9999));
        }
      },
    );
    if (action != TakeActionType.shareSite || !shareConfirmed) return;
    _isShareInFlight = true;
    try {
      final snapshot = await ServiceLocator.instance.sitesRepository.shareSite(
        site.id,
      );
      if (!mounted) return;
      setState(() => _shareCount = snapshot.sharesCount);
      _trackFeedEvent('share');
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.siteCardShareTrackFailedSnack,
          type: AppSnackType.warning,
        );
      }
    } finally {
      _isShareInFlight = false;
    }
  }

  Future<void> _openShareSheet() async {
    if (_isShareInFlight) return;
    final bool shareConfirmed = await TakeActionCoordinator.execute(
      context,
      action: TakeActionType.shareSite,
      site: site,
      isFromSiteDetail: false,
      onShareCountChanged: () {
        if (mounted) {
          setState(() => _shareCount = (_shareCount + 1).clamp(0, 9999));
        }
      },
    );
    if (!shareConfirmed) return;
    _isShareInFlight = true;
    try {
      final snapshot = await ServiceLocator.instance.sitesRepository.shareSite(
        site.id,
      );
      if (!mounted) return;
      setState(() => _shareCount = snapshot.sharesCount);
      _trackFeedEvent('share');
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.siteCardShareTrackFailedSnack,
          type: AppSnackType.warning,
        );
      }
    } finally {
      _isShareInFlight = false;
    }
  }

  Future<void> _showUpvotersSheet(BuildContext context) async {
    final int count = _upvoteCount.clamp(0, 999);
    if (count == 0) {
      AppSnack.show(
        context,
        message: context.l10n.siteDetailNoUpvotesSnack,
        type: AppSnackType.info,
      );
      return;
    }

    final List<String> names = <String>[
      'Community supporter',
      'Local resident',
      'Verified citizen',
    ];

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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusPill),
                ),
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

  String _formatDistance(double km) {
    if (km < 1) {
      final int meters = (km * 1000).round().clamp(1, 999);
      return '$meters m';
    }
    if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    }
    return '${km.toStringAsFixed(0)} km';
  }

  Comment _commentFromSiteCommentItem(SiteCommentItem item) {
    final String currentUserId = ServiceLocator.instance.authState.userId ?? '';
    return Comment(
      id: item.id,
      authorName: item.authorName,
      text: item.body,
      parentId: item.parentId,
      likeCount: item.likeCount,
      isLikedByMe: item.isLikedByMe,
      isOwnedByMe: item.authorId == currentUserId,
      replies: item.replies.map(_commentFromSiteCommentItem).toList(),
    );
  }

  String _dwellBucketForSeconds(int seconds) {
    if (seconds < 5) return '2_4s';
    if (seconds < 15) return '5_14s';
    if (seconds < 30) return '15_29s';
    return '30s_plus';
  }

  void _trackFeedEvent(String eventType, {Map<String, dynamic>? metadata}) {
    if (!ServiceLocator.instance.authState.isAuthenticated) return;
    unawaited(
      ServiceLocator.instance.sitesRepository.trackFeedEvent(
        site.id,
        eventType: eventType,
        sessionId: widget.feedSessionId,
        metadata: metadata,
      ),
    );
  }

  Future<void> _onFeedbackSelected(_FeedFeedbackAction action) async {
    final String feedbackType = switch (action) {
      _FeedFeedbackAction.notRelevant => 'not_relevant',
      _FeedFeedbackAction.showLess => 'show_more',
      _FeedFeedbackAction.duplicate => 'duplicate',
      _FeedFeedbackAction.misleading => 'misleading',
      _FeedFeedbackAction.hide => 'not_relevant',
    };
    try {
      await ServiceLocator.instance.sitesRepository.submitFeedFeedback(
        site.id,
        feedbackType: feedbackType,
        sessionId: widget.feedSessionId,
        metadata: <String, dynamic>{
          'source': 'feed_card_menu',
          'action': action.name,
        },
      );
      if (!mounted) return;
      AppSnack.show(
        context,
        message: action == _FeedFeedbackAction.hide
            ? 'Post hidden from your feed'
            : 'Thanks for your feedback',
        type: AppSnackType.info,
      );
      if (action == _FeedFeedbackAction.hide) {
        widget.onHidden?.call(site.id);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.siteCardFeedbackSubmitFailedSnack,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _openFeedbackSheet() async {
    AppHaptics.tap();
    final action = await showModalBottomSheet<_FeedFeedbackAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) => const _FeedFeedbackSheet(),
    );
    if (action == null) return;
    await _onFeedbackSelected(action);
  }
}

enum _FeedFeedbackAction { notRelevant, showLess, duplicate, misleading, hide }

class _FeedFeedbackSheet extends StatelessWidget {
  const _FeedFeedbackSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Feed options',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tune what you want to see',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _FeedbackTile(
                icon: Icons.visibility_off_outlined,
                title: context.l10n.siteCardNotRelevantTitle,
                onTap: () =>
                    Navigator.of(context).pop(_FeedFeedbackAction.notRelevant),
              ),
              _FeedbackTile(
                icon: Icons.auto_awesome_outlined,
                title: context.l10n.siteCardShowLessTitle,
                onTap: () =>
                    Navigator.of(context).pop(_FeedFeedbackAction.showLess),
              ),
              _FeedbackTile(
                icon: Icons.copy_all_outlined,
                title: context.l10n.siteCardDuplicateTitle,
                onTap: () =>
                    Navigator.of(context).pop(_FeedFeedbackAction.duplicate),
              ),
              _FeedbackTile(
                icon: Icons.warning_amber_rounded,
                title: context.l10n.siteCardMisleadingTitle,
                onTap: () =>
                    Navigator.of(context).pop(_FeedFeedbackAction.misleading),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              _FeedbackTile(
                icon: Icons.hide_source_rounded,
                title: context.l10n.siteCardHidePostTitle,
                isDestructive: true,
                onTap: () =>
                    Navigator.of(context).pop(_FeedFeedbackAction.hide),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isDestructive
        ? AppColors.accentDanger
        : AppColors.textPrimary;
    final Color textColor = isDestructive
        ? AppColors.accentDanger
        : AppColors.textPrimary;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: <Widget>[
              Icon(icon, size: AppSpacing.iconLg, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async' as async;
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class MapSearchModal extends StatefulWidget {
  const MapSearchModal({
    super.key,
    required this.allSites,
    required this.onResultTap,
    required this.onDismiss,
  });

  final List<PollutionSite> allSites;
  final ValueChanged<PollutionSite> onResultTap;
  final VoidCallback onDismiss;

  @override
  State<MapSearchModal> createState() => _MapSearchModalState();
}

class _MapSearchModalState extends State<MapSearchModal> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  async.Timer? _debounceTimer;

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = async.Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<PollutionSite>? _filteredResultsCache;
  String _filteredResultsQueryCache = '';

  List<PollutionSite> get _filteredResults {
    final String q = _controller.text.trim().toLowerCase();
    if (_filteredResultsCache != null && _filteredResultsQueryCache == q) {
      return _filteredResultsCache!;
    }
    _filteredResultsQueryCache = q;

    if (q.isEmpty) {
      _filteredResultsCache = widget.allSites;
      return _filteredResultsCache!;
    }
    final List<String> terms =
        q.split(RegExp(r'\s+')).where((String t) => t.isNotEmpty).toList();
    if (terms.isEmpty) {
      _filteredResultsCache = widget.allSites;
      return _filteredResultsCache!;
    }

    final List<PollutionSite> matches = widget.allSites.where((PollutionSite s) {
      final String title = s.title.toLowerCase();
      for (final String term in terms) {
        if (title.contains(term)) continue;
        final String type = (s.pollutionType ?? '').toLowerCase();
        if (type.contains(term)) continue;
        if (s.description.toLowerCase().contains(term)) continue;
        return false;
      }
      return true;
    }).toList();

    matches.sort((PollutionSite a, PollutionSite b) {
      final String aTitle = a.title.toLowerCase();
      final String bTitle = b.title.toLowerCase();
      final int aExact = aTitle == q ? 0 : aTitle.startsWith(q) ? 1 : 2;
      final int bExact = bTitle == q ? 0 : bTitle.startsWith(q) ? 1 : 2;
      if (aExact != bExact) return aExact.compareTo(bExact);
      return aTitle.compareTo(bTitle);
    });
    _filteredResultsCache = matches;
    return matches;
  }

  Widget _buildModalContent(
    BuildContext context, {
    required bool isCompact,
    required double maxContentWidth,
    required List<PollutionSite> results,
    required bool isEmpty,
    required bool hasQuery,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableHeight = constraints.maxHeight;
        final double modalHeight = availableHeight.clamp(
          isCompact ? 340 : 420,
          isCompact ? 620 : 720,
        );
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxContentWidth,
            maxHeight: modalHeight,
          ),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: double.infinity,
                    height: modalHeight,
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.7),
                        width: 1,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 4),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            isCompact ? AppSpacing.sm : AppSpacing.lg,
                            AppSpacing.xs,
                            isCompact ? AppSpacing.sm : AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    filled: false,
                                    hintText: 'Search pollution sites',
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textMuted
                                              .withValues(alpha: 0.9),
                                          fontSize: isCompact ? 16 : 17,
                                          letterSpacing: -0.2,
                                        ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16, right: 10),
                                      child: Icon(
                                        Icons.search_rounded,
                                        size: isCompact ? 21 : 22,
                                        color: AppColors.textMuted
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                    suffixIcon: _controller.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.cancel_rounded,
                                              size: 18,
                                              color: AppColors.textMuted,
                                            ),
                                            onPressed: () {
                                              _controller.clear();
                                              if (mounted) setState(() {});
                                            },
                                            style: IconButton.styleFrom(
                                              minimumSize: const Size(40, 40),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: isCompact ? 14 : 16,
                                    ),
                                    isDense: true,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontSize: isCompact ? 16 : 17,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                              ),
                              SizedBox(width: isCompact ? 8 : 12),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.onDismiss,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Text(
                                      'Cancel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEmpty)
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: isCompact
                                        ? AppSpacing.lg
                                        : AppSpacing.xl,
                                    vertical: isCompact
                                        ? AppSpacing.xl
                                        : AppSpacing.xxl),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      width: isCompact ? 56 : 64,
                                      height: isCompact ? 56 : 64,
                                      decoration: BoxDecoration(
                                        color: AppColors.inputFill
                                            .withValues(alpha: 0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        hasQuery
                                            ? Icons.search_off_rounded
                                            : Icons.place_rounded,
                                        size: isCompact ? 28 : 32,
                                        color: AppColors.textMuted
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    SizedBox(
                                        height: isCompact
                                            ? AppSpacing.md
                                            : AppSpacing.lg),
                                    Text(
                                      hasQuery
                                          ? 'No matching sites'
                                          : 'Start typing to search',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: isCompact ? 16 : 17,
                                            letterSpacing: -0.3,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (hasQuery)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: AppSpacing.sm),
                                        child: Text(
                                          'Try a different search term',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textMuted,
                                                fontSize: isCompact ? 14 : 15,
                                                height: 1.4,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: AppSpacing.xs),
                                        child: Text(
                                          'Find pollution sites by name or type',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textMuted,
                                                fontSize: isCompact ? 14 : 15,
                                                height: 1.4,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (ScrollNotification n) {
                                if (n is ScrollStartNotification &&
                                    n.dragDetails != null) {
                                  _focusNode.unfocus();
                                }
                                return false;
                              },
                              child: ListView.separated(
                                controller: _scrollController,
                                addAutomaticKeepAlives: true,
                                addRepaintBoundaries: true,
                                addSemanticIndexes: false,
                                cacheExtent: 300,
                                padding: EdgeInsets.only(
                                  top: 8,
                                  bottom: isCompact
                                      ? AppSpacing.lg
                                      : AppSpacing.xl,
                                  left: isCompact
                                      ? AppSpacing.sm
                                      : AppSpacing.lg,
                                  right: isCompact
                                      ? AppSpacing.sm
                                      : AppSpacing.lg,
                                ),
                                itemCount: results.length,
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                separatorBuilder:
                                    (BuildContext context, int index) {
                                  return Divider(
                                    height: 1,
                                    indent: 0,
                                    endIndent: 0,
                                    color: AppColors.divider
                                        .withValues(alpha: 0.35),
                                  );
                                },
                                itemBuilder: (BuildContext context, int index) {
                                  final PollutionSite site = results[index];
                                  return RepaintBoundary(
                                    child: _SearchResultTile(
                                      site: site,
                                      onTap: () => widget.onResultTap(site),
                                      compact: isCompact,
                                    ),
                                  );
                                },
                              ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double screenH = mq.size.height;
    final double screenW = mq.size.width;
    final bool isCompact = screenW < 400 || screenH < 600;
    final double horizontalPadding = isCompact ? AppSpacing.sm : AppSpacing.md;
    final double maxContentWidth =
        screenW > 600 ? 480.0 : double.infinity;
    final List<PollutionSite> results = _filteredResults;
    final bool isEmpty = results.isEmpty;
    final bool hasQuery = _controller.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        widget.onDismiss();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          top: math.max(mq.padding.top, 44) + (isCompact ? 8 : AppSpacing.sm),
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: mq.padding.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: Align(
            alignment: Alignment.topCenter,
            child: _buildModalContent(
              context,
              isCompact: isCompact,
              maxContentWidth: maxContentWidth,
              results: results,
              isEmpty: isEmpty,
              hasQuery: hasQuery,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.site,
    required this.onTap,
    this.compact = false,
  });

  final PollutionSite site;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double thumbSize = compact ? 48 : 52;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: compact ? 12 : 14,
          ),
          child: Row(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: SizedBox(
                    width: thumbSize,
                    height: thumbSize,
                    child: Image(
                      image: site.imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 12 : AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      site.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 15 : 16,
                            letterSpacing: -0.2,
                            height: 1.3,
                          ),
                    ),
                    if (site.pollutionType != null ||
                        site.statusLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        site.pollutionType ?? site.statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: compact ? 12 : 13,
                              letterSpacing: -0.1,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: compact ? 20 : 22,
                color: AppColors.textMuted.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

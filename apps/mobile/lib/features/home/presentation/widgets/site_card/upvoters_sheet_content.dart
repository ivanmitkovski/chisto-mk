import 'dart:async';

import 'package:chisto_mobile/core/theme/app_radii.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_upvoters_provider.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_avatar.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:chisto_mobile/shared/widgets/molecules/notification_row_highlight.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet listing users who upvoted a site (paginated via [siteUpvotersNotifierProvider]).
class UpvotersSheetContent extends ConsumerStatefulWidget {
  const UpvotersSheetContent({
    super.key,
    required this.siteId,
    required this.scrollController,
    this.highlightUserId,
  });

  final String siteId;
  final ScrollController scrollController;
  final String? highlightUserId;

  @override
  ConsumerState<UpvotersSheetContent> createState() => _UpvotersSheetContentState();
}

class _UpvotersSheetContentState extends ConsumerState<UpvotersSheetContent> {
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  String? _activeHighlightUserId;
  Timer? _highlightTimer;
  bool _highlightCompleted = false;

  GlobalKey _rowKeyFor(String userId) =>
      _rowKeys.putIfAbsent(userId, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onUpvotersLoaded(SiteUpvotersState? previous, SiteUpvotersState next) {
    if (next.initialLoading) return;
    _tryHighlightUpvoter(next);
  }

  void _tryHighlightUpvoter(SiteUpvotersState data) {
    if (_highlightCompleted) return;
    final String? userId = widget.highlightUserId?.trim();
    if (userId == null || userId.isEmpty) return;

    final bool found =
        data.items.any((SiteUpvoterItem item) => item.userId == userId);
    if (!found) return;

    scheduleNotificationRowHighlight(
      targetId: userId,
      rowKey: _rowKeyFor(userId),
      delay: const Duration(milliseconds: 320),
      onHighlight: () {
        if (!mounted) return;
        _highlightCompleted = true;
        setState(() => _activeHighlightUserId = userId);
        _highlightTimer?.cancel();
        _highlightTimer = Timer(NotificationRowHighlight.highlightDuration, () {
          if (mounted) {
            setState(() => _activeHighlightUserId = null);
          }
        });
      },
    );
  }

  void _onScroll() {
    final SiteUpvotersState s =
        ref.read(siteUpvotersNotifierProvider(widget.siteId));
    if (s.initialLoading || s.loadingMore || !s.hasMore) {
      return;
    }
    if (!widget.scrollController.hasClients) {
      return;
    }
    final ScrollPosition pos = widget.scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 240) {
      return;
    }
    ref.read(siteUpvotersNotifierProvider(widget.siteId).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final SiteUpvotersState data =
        ref.watch(siteUpvotersNotifierProvider(widget.siteId));

    ref.listen<SiteUpvotersState>(
      siteUpvotersNotifierProvider(widget.siteId),
      _onUpvotersLoaded,
    );

    final String subtitle = data.initialLoading
        ? ''
        : data.error != null && data.items.isEmpty
            ? ''
            : context.l10n.siteUpvotersSupportersCount(data.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: AppRadii.circle,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.siteUpvotersSheetTitle,
                style: AppTypography.sheetTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.cardSubtitle.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              const Divider(height: 1, color: AppColors.divider),
            ],
          ),
        ),
        Expanded(
          child: _buildBody(context, data),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, SiteUpvotersState data) {
    if (data.initialLoading) {
      return Center(child: AppLoadingIndicator());
    }
    if (data.error != null && data.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                context.l10n.siteUpvotersLoadFailed,
                textAlign: TextAlign.center,
                style: AppTypography.cardSubtitle.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.text(
                label: context.l10n.siteUpvotersRetry,
                onPressed: () => ref
                    .read(siteUpvotersNotifierProvider(widget.siteId).notifier)
                    .loadInitial(),
              ),
            ],
          ),
        ),
      );
    }
    if (data.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            context.l10n.siteDetailNoUpvotesSnack,
            textAlign: TextAlign.center,
            style: AppTypography.cardSubtitle.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      itemCount: data.items.length + (data.loadingMore && data.hasMore ? 1 : 0),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (BuildContext context, int index) {
        if (index >= data.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: AppLoadingIndicator(size: AppLoadingIndicatorSize.sm),
              ),
            ),
          );
        }
        final SiteUpvoterItem item = data.items[index];
        final bool highlighted =
            _activeHighlightUserId != null && _activeHighlightUserId == item.userId;
        final Widget row = ListTile(
          minLeadingWidth: 48,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          leading: AppAvatar(
            key: ValueKey<String>('${item.userId}|${item.avatarUrl ?? ''}'),
            name: item.displayName,
            size: 40,
            fontSize: 14,
            imageUrl: item.avatarUrl,
          ),
          title: Text(
            item.displayName,
            style: AppTypography.cardTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          trailing: Text(
            context.l10n.siteUpvotersSupportingLabel,
            style: AppTypography.cardSubtitle.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        );
        return KeyedSubtree(
          key: _rowKeyFor(item.userId),
          child: NotificationRowHighlight(
            highlighted: highlighted,
            child: row,
          ),
        );
      },
    );
  }
}

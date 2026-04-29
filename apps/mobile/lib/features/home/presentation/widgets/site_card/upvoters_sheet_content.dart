import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_upvoters_provider.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet listing users who upvoted a site (paginated via [siteUpvotersNotifierProvider]).
class UpvotersSheetContent extends ConsumerStatefulWidget {
  const UpvotersSheetContent({
    super.key,
    required this.siteId,
    required this.scrollController,
  });

  final String siteId;
  final ScrollController scrollController;

  @override
  ConsumerState<UpvotersSheetContent> createState() => _UpvotersSheetContentState();
}

class _UpvotersSheetContentState extends ConsumerState<UpvotersSheetContent> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
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
                    borderRadius: BorderRadius.circular(999),
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
      return const Center(child: CircularProgressIndicator());
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
              TextButton(
                onPressed: () => ref
                    .read(siteUpvotersNotifierProvider(widget.siteId).notifier)
                    .loadInitial(),
                child: Text(context.l10n.siteUpvotersRetry),
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
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final SiteUpvoterItem item = data.items[index];
        return ListTile(
          key: ValueKey<String>(item.userId),
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
      },
    );
  }
}

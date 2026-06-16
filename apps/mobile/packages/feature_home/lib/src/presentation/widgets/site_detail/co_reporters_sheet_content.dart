import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/utils/civic_actor_display.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_avatar.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/presentation/providers/site_co_reporters_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet listing co-reporters for a site (paginated via [siteCoReportersNotifierProvider]).
class CoReportersSheetContent extends ConsumerStatefulWidget {
  const CoReportersSheetContent({
    super.key,
    required this.siteId,
    required this.scrollController,
    this.sheetController,
    this.sizeConfig,
  });

  final String siteId;
  final ScrollController scrollController;
  final DraggableScrollableController? sheetController;
  final AppSheetSizeConfig? sizeConfig;

  @override
  ConsumerState<CoReportersSheetContent> createState() =>
      _CoReportersSheetContentState();
}

class _CoReportersSheetContentState
    extends ConsumerState<CoReportersSheetContent> {
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
    final SiteCoReportersState s = ref.read(
      siteCoReportersNotifierProvider(widget.siteId),
    );
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
    ref
        .read(siteCoReportersNotifierProvider(widget.siteId).notifier)
        .loadMore();
  }

  String _displayName(SiteCoReporterItem item) {
    return civicActorDisplayLabel(
      context.l10n,
      displayName: item.displayName,
      isDeleted: item.isDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SiteCoReportersState data = ref.watch(
      siteCoReportersNotifierProvider(widget.siteId),
    );
    final String subtitle = data.initialLoading
        ? ''
        : context.l10n.siteDetailCoReportersSubtitle(data.total);

    final Widget header = _buildHeader(context, subtitle);
    final Widget scrollBody = CustomScrollView(
      controller: widget.scrollController,
      slivers: _contentSlivers(context, data),
    );

    if (widget.sheetController != null && widget.sizeConfig != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppResizableSheetHeader(
            sheetController: widget.sheetController!,
            sizeConfig: widget.sizeConfig!,
            child: header,
          ),
          Expanded(child: scrollBody),
        ],
      );
    }

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: <Widget>[
        SliverToBoxAdapter(child: header),
        ..._contentSlivers(context, data),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.sheetController == null)
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
          if (widget.sheetController == null)
            const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.siteDetailCoReportersTitle,
            style: AppTypographySurfaces.homeCoReportersTitle(
              Theme.of(context).textTheme,
            ),
          ),
          if (subtitle.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypographySurfaces.homeCoReportersSubtitle(
                Theme.of(context).textTheme,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  List<Widget> _contentSlivers(
    BuildContext context,
    SiteCoReportersState data,
  ) {
    return <Widget>[
      if (data.initialLoading)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: AppLoadingIndicator()),
        )
      else if (data.error != null)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  context.l10n.siteCoReportersLoadFailed,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: context.l10n.siteCoReportersRetry,
                  onPressed: () => ref
                      .read(
                        siteCoReportersNotifierProvider(widget.siteId).notifier,
                      )
                      .loadInitial(),
                ),
              ],
            ),
          ),
        )
      else if (data.items.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              context.l10n.siteDetailNoCoReportersSnack,
              textAlign: TextAlign.center,
            ),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            if (index >= data.items.length) {
              return data.loadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: AppLoadingIndicator()),
                    )
                  : const SizedBox.shrink();
            }
            final SiteCoReporterItem item = data.items[index];
            final String name = _displayName(item);
            return ListTile(
              leading: AppAvatar(
                name: name,
                size: 40,
                fontSize: 14,
                imageUrl: item.isDeleted ? null : item.avatarUrl,
              ),
              title: Text(name),
              subtitle: item.isOriginalReporter
                  ? Text(
                      context.l10n.siteCoReportersOriginalReporterLabel,
                      style: AppTypography.cardSubtitle(
                        Theme.of(context).textTheme,
                      ).copyWith(color: AppColors.textSecondary),
                    )
                  : null,
            );
          }, childCount: data.items.length + (data.loadingMore ? 1 : 0)),
        ),
      SliverPadding(
        padding: EdgeInsets.only(
          bottom: AppBottomSheet.homeIndicatorScrollPadding(context),
        ),
      ),
    ];
  }
}

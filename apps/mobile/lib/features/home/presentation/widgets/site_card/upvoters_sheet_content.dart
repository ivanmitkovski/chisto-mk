import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';

/// Bottom sheet listing users who upvoted a site (loads from the API).
class UpvotersSheetContent extends StatefulWidget {
  const UpvotersSheetContent({
    super.key,
    required this.siteId,
    required this.scrollController,
  });

  final String siteId;
  final ScrollController scrollController;

  @override
  State<UpvotersSheetContent> createState() => _UpvotersSheetContentState();
}

class _UpvotersSheetContentState extends State<UpvotersSheetContent> {
  static const int _pageSize = 50;

  Future<SiteUpvotesResult>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = ServiceLocator.instance.sitesRepository.getSiteUpvotes(
        widget.siteId,
        page: 1,
        limit: _pageSize,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SiteUpvotesResult>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<SiteUpvotesResult> snapshot) {
        final bool waiting =
            snapshot.connectionState == ConnectionState.waiting;
        final Object? err = snapshot.error;
        final SiteUpvotesResult? data = snapshot.data;

        final String subtitle;
        if (waiting) {
          subtitle = '';
        } else if (err != null) {
          subtitle = '';
        } else if (data != null) {
          subtitle = context.l10n.siteUpvotersSupportersCount(data.total);
        } else {
          subtitle = '';
        }

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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              child: _buildBody(context, waiting, err, data),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool waiting,
    Object? err,
    SiteUpvotesResult? data,
  ) {
    if (waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                context.l10n.siteUpvotersLoadFailed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _reload,
                child: Text(context.l10n.siteUpvotersRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (data == null || data.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            context.l10n.siteDetailNoUpvotesSnack,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      itemCount: data.items.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (BuildContext context, int index) {
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          trailing: Text(
            context.l10n.siteUpvotersSupportingLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        );
      },
    );
  }
}

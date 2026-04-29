import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/site_report.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_image_resolver.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';
import 'package:chisto_mobile/shared/widgets/immersive_photo_gallery.dart';

class FirstReportModal extends StatelessWidget {
  const FirstReportModal({
    super.key,
    required this.report,
  });

  final SiteReport report;

  static Future<void> show(BuildContext context, SiteReport report) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (BuildContext context) => FirstReportModal(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ImageProvider> galleryProviders =
        siteReportGalleryImageProviders(report);
    final List<GalleryImageItem> galleryItems = galleryProviders
        .asMap()
        .entries
        .map(
          (MapEntry<int, ImageProvider> e) => GalleryImageItem(
            image: e.value,
            heroTag: 'first-report-${report.id}-${e.key}',
            semanticLabel: context.l10n.semanticsReportPhotoNumber(e.key + 1),
          ),
        )
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return CustomScrollView(
          controller: scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
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
                    Row(
                      children: <Widget>[
                        AppAvatar(
                          name: report.reporterName,
                          size: 40,
                          fontSize: 14,
                          imageUrl: report.reporterAvatarUrl,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                report.reporterName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                report.reportedAgo,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (galleryItems.isNotEmpty) ...<Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        child: SizedBox(
                          height: 200,
                          child: ImmersivePhotoGallery(
                            items: galleryItems,
                            aspectRatio: 16 / 9,
                            borderRadius: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      report.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    if (report.description != null &&
                        report.description!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        report.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

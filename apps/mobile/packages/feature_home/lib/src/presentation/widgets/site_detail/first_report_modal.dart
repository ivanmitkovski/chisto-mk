import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/utils/civic_actor_display.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_avatar.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/immersive_photo_gallery.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/site_report.dart';
import 'package:feature_home/src/presentation/utils/site_image_resolver.dart';
import 'package:flutter/material.dart';

class FirstReportModal extends StatelessWidget {
  const FirstReportModal({
    super.key,
    required this.report,
    required this.scrollController,
    this.sheetController,
    this.sizeConfig,
  });

  final SiteReport report;
  final ScrollController scrollController;
  final DraggableScrollableController? sheetController;
  final AppSheetSizeConfig? sizeConfig;

  static Future<void> show(BuildContext context, SiteReport report) {
    return AppBottomSheet.showResizable<void>(
      context: context,
      sizeConfig: const AppSheetSizeConfig(
        minSize: 0.5,
        maxSize: 0.95,
        initialSize: 0.75,
      ),
      builder:
          (
            BuildContext sheetContext,
            ScrollController scrollController,
            DraggableScrollableController sheetController,
            AppSheetSizeConfig sizeConfig,
          ) {
            return FirstReportModal(
              report: report,
              scrollController: scrollController,
              sheetController: sheetController,
              sizeConfig: sizeConfig,
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String reporterLabel = civicActorDisplayLabel(
      context.l10n,
      displayName: report.reporterName,
      isDeleted: report.reporterIsDeleted,
    );
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

    final Widget body = CustomScrollView(
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
            child: _buildContent(context, reporterLabel, galleryItems),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: AppBottomSheet.homeIndicatorScrollPadding(context),
          ),
        ),
      ],
    );

    if (sheetController != null && sizeConfig != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppResizableSheetHeader(
            sheetController: sheetController!,
            sizeConfig: sizeConfig!,
          ),
          Expanded(child: body),
        ],
      );
    }

    return body;
  }

  Widget _buildContent(
    BuildContext context,
    String reporterLabel,
    List<GalleryImageItem> galleryItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (sheetController == null) ...<Widget>[
          Center(
            child: Container(
              width: AppSpacing.sheetHandle,
              height: AppSpacing.sheetHandleHeight,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(
                  AppSpacing.radiusXs,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: <Widget>[
            AppAvatar(
              name: reporterLabel,
              size: 40,
              fontSize: 14,
              imageUrl: report.reporterIsDeleted
                  ? null
                  : report.reporterAvatarUrl,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    reporterLabel,
                    style: AppTypography.cardTitle(Theme.of(context).textTheme),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.reportedAgo,
                    style: AppTypography.cardSubtitle(
                      Theme.of(context).textTheme,
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
            borderRadius: BorderRadius.circular(
              AppSpacing.radiusLg,
            ),
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
          style: AppTypographySurfaces.homeFirstReportTitle(
            Theme.of(context).textTheme,
          ),
        ),
        if (report.description != null &&
            report.description!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            report.description!,
            style: AppTypographySurfaces.homeFirstReportBody(
              Theme.of(context).textTheme,
            ),
          ),
        ],
      ],
    );
  }
}

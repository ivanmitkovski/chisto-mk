import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/immersive_photo_gallery.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/repositories/site_resolution_repository.dart';
import 'package:feature_home/src/presentation/utils/open_mark_site_as_cleaned.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportCleanupSubmissionSlot extends ConsumerStatefulWidget {
  const ReportCleanupSubmissionSlot({
    super.key,
    required this.siteId,
    required this.reportApproved,
    this.snapshot,
  });

  final String siteId;
  final bool reportApproved;
  final ReportSheetViewModel? snapshot;

  @override
  ConsumerState<ReportCleanupSubmissionSlot> createState() =>
      _ReportCleanupSubmissionSlotState();
}

class _ReportCleanupSubmissionSlotState
    extends ConsumerState<ReportCleanupSubmissionSlot> {
  SiteResolutionListResult? _result;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final SiteResolutionListResult result = await ref
          .read(sitesRepositoryProvider)
          .listSiteResolutions(widget.siteId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _isLoading = false;
      });
    }
  }

  SiteResolutionListItem? get _mySubmission {
    for (final SiteResolutionListItem item in _result?.items ?? const []) {
      if (item.isSelf) return item;
    }
    return null;
  }

  Future<void> _openMarkAsCleaned() async {
    final ReportSheetViewModel? snapshot = widget.snapshot;
    if (snapshot == null) return;
    await openMarkSiteAsCleanedFromReport(
      context: context,
      ref: ref,
      siteId: widget.siteId,
      snapshot: snapshot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Center(child: AppLoadingIndicator()),
      );
    }
    if (_loadFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppInlineBanner(
            message: l10n.reportCleanupSubmissionLoadFailed,
            tone: AppInlineBannerTone.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: _load, child: Text(l10n.commonRetry)),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    }

    final SiteResolutionListItem? mine = _mySubmission;
    if (mine != null) {
      final bool pending = mine.status.toUpperCase() == 'PENDING';
      final String title = pending
          ? l10n.reportCleanupSubmissionPendingTitle
          : l10n.reportCleanupSubmissionApprovedTitle;
      final String message = pending
          ? l10n.reportCleanupSubmissionPendingBody
          : l10n.reportCleanupSubmissionApprovedBody;
      final List<GalleryImageItem> galleryItems = mine.mediaUrls
          .asMap()
          .entries
          .map(
            (MapEntry<int, String> entry) => GalleryImageItem(
              image: NetworkImage(entry.value),
              heroTag: 'report-cleanup-${mine.id}-${entry.key}',
              semanticLabel: l10n.reportCleanupSubmissionPhotoSemantic,
            ),
          )
          .toList(growable: false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ReportInfoBanner(
            title: title,
            icon: pending
                ? Icons.hourglass_top_rounded
                : Icons.verified_rounded,
            tone: pending
                ? ReportSurfaceTone.neutral
                : ReportSurfaceTone.success,
            message: message,
            titleStyle: AppTypography.cardTitle(textTheme),
            messageStyle: AppTypography.cardSubtitle(textTheme),
          ),
          if (galleryItems.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            ImmersivePhotoGallery(
              items: galleryItems,
              openLabel: l10n.reportCleanupSubmissionOpenGallerySemantic,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    }

    if (widget.reportApproved && widget.snapshot != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            label: l10n.reportDetailMarkAsCleanedCta,
            onPressed: _openMarkAsCleaned,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

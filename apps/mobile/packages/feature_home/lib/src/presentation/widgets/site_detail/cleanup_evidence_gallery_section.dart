import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/immersive_photo_gallery.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/repositories/site_resolution_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CleanupEvidenceGallerySection extends ConsumerStatefulWidget {
  const CleanupEvidenceGallerySection({super.key, required this.siteId});

  final String siteId;

  @override
  ConsumerState<CleanupEvidenceGallerySection> createState() =>
      _CleanupEvidenceGallerySectionState();
}

class _CleanupEvidenceGallerySectionState
    extends ConsumerState<CleanupEvidenceGallerySection> {
  CleanupEvidenceListResult? _result;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final CleanupEvidenceListResult result = await ref
          .read(sitesRepositoryProvider)
          .getCleanupEvidence(widget.siteId);
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

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: AppLoadingIndicator()),
      );
    }
    if (_loadFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppInlineBanner(
            message: l10n.cleanupEvidenceLoadFailed,
            tone: AppInlineBannerTone.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.text(label: l10n.commonRetry, onPressed: _load),
        ],
      );
    }
    final List<CleanupEvidenceItem> items =
        _result?.items ?? const <CleanupEvidenceItem>[];
    if (items.isEmpty) {
      return Text(
        l10n.cleanupEvidenceEmpty,
        style: AppTypography.cardSubtitle(textTheme).copyWith(
          color: AppColors.textMuted,
        ),
      );
    }
    final List<GalleryImageItem> galleryItems = items
        .map(
          (CleanupEvidenceItem item) => GalleryImageItem(
            image: NetworkImage(item.url),
            heroTag: 'cleanup-evidence-${item.id}',
            semanticLabel: item.submitterDisplayLabel ??
                l10n.cleanupEvidencePhotoSemantic,
          ),
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.cleanupEvidenceSectionTitle,
          style: AppTypography.cardTitle(textTheme).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ImmersivePhotoGallery(
          items: galleryItems,
          openLabel: l10n.cleanupEvidenceOpenGallerySemantic,
        ),
      ],
    );
  }
}

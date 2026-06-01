import 'package:cached_network_image/cached_network_image.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

enum ShareAction { copyLink, sendMessage }

/// Site share options sheet (copy link, system share).
class ShareSheet extends StatelessWidget {
  const ShareSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.siteTitle,
    required this.shareUrl,
    this.siteImageUrl,
  });

  final String title;
  final String subtitle;
  final String siteTitle;
  final String shareUrl;
  final String? siteImageUrl;

  @override
  Widget build(BuildContext context) {
    final String hostLabel = _hostLabel(shareUrl);
    return AppSheetScaffold(
      title: title,
      subtitle: subtitle,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      trailing: AppCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: context.l10n.commonClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ShareLinkPreview(
              siteTitle: siteTitle,
              hostLabel: hostLabel,
              shareUrl: shareUrl,
              imageUrl: siteImageUrl,
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Semantics(
                button: true,
                label: context.l10n.shareSheetCopyLinkSemantic,
                child: AppActionTile(
                  icon: Icons.link_rounded,
                  title: context.l10n.shareSheetCopyLinkTitle,
                  subtitle: context.l10n.shareSheetCopyLinkSubtitle,
                  variant: AppActionTileVariant.compact,
                  onTap: () => Navigator.of(context).pop(ShareAction.copyLink),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: context.l10n.shareSheetSendSemantic,
              child: AppActionTile(
                icon: Icons.send_rounded,
                title: context.l10n.shareSheetSendTitle,
                subtitle: context.l10n.shareSheetSendSubtitle,
                variant: AppActionTileVariant.compact,
                onTap: () => Navigator.of(context).pop(ShareAction.sendMessage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _hostLabel(String url) {
  try {
    final Uri u = Uri.parse(url);
    if (u.hasAuthority) {
      return u.host;
    }
  } catch (_) {
    // ignore
  }
  return url;
}

class _ShareLinkPreview extends StatelessWidget {
  const _ShareLinkPreview({
    required this.siteTitle,
    required this.hostLabel,
    required this.shareUrl,
    this.imageUrl,
  });

  final String siteTitle;
  final String hostLabel;
  final String shareUrl;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String trimmedImage = imageUrl?.trim() ?? '';
    final bool showImage =
        trimmedImage.isNotEmpty &&
        (trimmedImage.startsWith('http://') ||
            trimmedImage.startsWith('https://'));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputFill.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radius14),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (showImage) ...<Widget>[
              ClipRRect(
                borderRadius: AppRadii.sm,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CachedNetworkImage(
                    imageUrl: trimmedImage,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    memCacheWidth: 132,
                    memCacheHeight: 132,
                    errorWidget:
                        (BuildContext context, String url, Object error) =>
                            const ColoredBox(
                              color: AppColors.inputFill,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textMuted,
                                size: 22,
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    siteTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypographySurfaces.profilePointsActivityTitle(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hostLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypographySurfaces.homeMutedCaption(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  Text(
                    shareUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypographySurfaces.reportsLocationAddressBadge(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

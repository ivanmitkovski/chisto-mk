import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusPill)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                label: context.l10n.shareSheetSemanticDragHandle,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.inputBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ShareLinkPreview(
                siteTitle: siteTitle,
                hostLabel: hostLabel,
                shareUrl: shareUrl,
                imageUrl: siteImageUrl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              ShareActionTile(
                icon: Icons.link_rounded,
                title: context.l10n.shareSheetCopyLinkTitle,
                subtitle: context.l10n.shareSheetCopyLinkSubtitle,
                semanticsLabel: context.l10n.shareSheetCopyLinkSemantic,
                onTap: () => Navigator.of(context).pop(ShareAction.copyLink),
              ),
              ShareActionTile(
                icon: Icons.send_rounded,
                title: context.l10n.shareSheetSendTitle,
                subtitle: context.l10n.shareSheetSendSubtitle,
                semanticsLabel: context.l10n.shareSheetSendSemantic,
                onTap: () => Navigator.of(context).pop(ShareAction.sendMessage),
              ),
            ],
          ),
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
    final bool showImage = trimmedImage.isNotEmpty &&
        (trimmedImage.startsWith('http://') || trimmedImage.startsWith('https://'));
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
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Image.network(
                    trimmedImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: AppColors.inputFill,
                      child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 22),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hostLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    shareUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
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

class ShareActionTile extends StatelessWidget {
  const ShareActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        label: semanticsLabel ?? title,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radius14),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radius14),
                color: AppColors.inputFill.withValues(alpha: 0.6),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

/// Site cover for [EcoEvent.siteImageUrl]: HTTPS URLs from the API, local
/// `assets/…` paths, or empty (placeholder).
class EcoEventCoverImage extends StatelessWidget {
  const EcoEventCoverImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.imageUnavailableLabel,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  /// Shown under the icon when a network/asset image fails to load (a11y).
  final String? imageUnavailableLabel;

  static bool isNetworkUrl(String raw) {
    final String t = raw.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.inputFill,
      alignment: errorWidget != null ? Alignment.center : null,
      child: errorWidget,
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.inputFill,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    if (errorWidget != null) {
      return _placeholder();
    }
    final String? label = imageUnavailableLabel;
    return Container(
      width: width,
      height: height,
      color: AppColors.inputFill,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textMuted,
            size: 28,
          ),
          if (label != null && label.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String t = path.trim();
    if (t.isEmpty) {
      return _placeholder();
    }
    if (isNetworkUrl(t)) {
      final double dpr = MediaQuery.devicePixelRatioOf(context);
      int? memW;
      int? memH;
      final double? w = width;
      final double? h = height;
      if (w != null &&
          h != null &&
          w.isFinite &&
          h.isFinite &&
          w > 0 &&
          h > 0) {
        memW = (w * dpr).round().clamp(1, 8192);
        memH = (h * dpr).round().clamp(1, 8192);
      }
      return CachedNetworkImage(
        imageUrl: t,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memW,
        memCacheHeight: memH,
        fadeInDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
        placeholder: (BuildContext context, String _) => _loadingPlaceholder(),
        errorWidget: (BuildContext ctx, String _, Object _) => _errorPlaceholder(ctx),
      );
    }
    return Image.asset(
      t,
      width: width,
      height: height,
      fit: fit,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return _errorPlaceholder(context);
      },
    );
  }
}

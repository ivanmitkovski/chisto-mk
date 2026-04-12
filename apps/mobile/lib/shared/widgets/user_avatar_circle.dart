import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

/// First Unicode scalar for [displayName], uppercased (works for Cyrillic and Latin).
String userAvatarInitial(String displayName) {
  final String t = displayName.trim();
  if (t.isEmpty) {
    return '?';
  }
  final Runes runes = t.runes;
  if (runes.isEmpty) {
    return '?';
  }
  return String.fromCharCode(runes.first).toUpperCase();
}

Color userAvatarFallbackColor(String? seed, String displayName) {
  final String key = (seed != null && seed.isNotEmpty) ? seed : displayName;
  if (key.isEmpty) {
    return AppColors.avatarPalette[0];
  }
  int h = 0;
  for (final int u in key.runes) {
    h = 0x1fffffff & (h + u);
    h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
    h ^= h >> 6;
  }
  h = 0x1fffffff & (h + ((h & 0x03ff) << 15));
  h ^= h >> 11;
  return AppColors.avatarPalette[h.abs() % AppColors.avatarPalette.length];
}

/// Network profile photo when [imageUrl] is non-empty; otherwise initials on a stable color.
class UserAvatarCircle extends StatelessWidget {
  const UserAvatarCircle({
    super.key,
    required this.displayName,
    this.imageUrl,
    required this.size,
    this.seed,
    this.fallbackStyle = UserAvatarFallbackStyle.solid,
  });

  final String displayName;
  final String? imageUrl;
  final double size;
  final String? seed;
  final UserAvatarFallbackStyle fallbackStyle;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl?.trim();
    final bool hasUrl = url != null && url.isNotEmpty;
    final Color base = userAvatarFallbackColor(seed, displayName);
    final String initial = userAvatarInitial(displayName);

    final Widget fallback = _FallbackInitials(
      base: base,
      initial: initial,
      size: size,
      style: fallbackStyle,
    );

    if (!hasUrl) {
      return fallback;
    }

    final int cachePx = (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(48, 512);

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: cachePx,
          memCacheHeight: cachePx,
          fadeInDuration: const Duration(milliseconds: 120),
          errorWidget: (BuildContext context, String url, Object error) => fallback,
          placeholder: (BuildContext context, String url) => fallback,
        ),
      ),
    );
  }
}

enum UserAvatarFallbackStyle {
  /// Solid fill + white initials (rosters, cards).
  solid,

  /// Light tint + saturated letter (chat bubbles).
  softTint,
}

class _FallbackInitials extends StatelessWidget {
  const _FallbackInitials({
    required this.base,
    required this.initial,
    required this.size,
    required this.style,
  });

  final Color base;
  final String initial;
  final double size;
  final UserAvatarFallbackStyle style;

  @override
  Widget build(BuildContext context) {
    final bool solid = style == UserAvatarFallbackStyle.solid;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: solid ? base : base.withValues(alpha: 0.18),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: (size * 0.38).clamp(10, 22),
          fontWeight: FontWeight.w700,
          color: solid ? AppColors.white : base,
        ),
      ),
    );
  }
}

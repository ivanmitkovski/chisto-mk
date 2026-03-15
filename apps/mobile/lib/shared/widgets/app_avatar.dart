import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = AppSpacing.avatarMd,
    this.fontSize,
    this.imageUrl,
  });

  final String name;
  final double size;
  final double? fontSize;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final int colorIndex = name.hashCode.abs() % AppColors.avatarPalette.length;
    final Color bg = AppColors.avatarPalette[colorIndex];
    final String initials = _initials(name);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _InitialsCircle(
            initials: initials,
            color: bg,
            size: size,
            fontSize: fontSize,
          ),
        ),
      );
    }

    return _InitialsCircle(
      initials: initials,
      color: bg,
      size: size,
      fontSize: fontSize,
    );
  }

  static String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({
    required this.initials,
    required this.color,
    required this.size,
    this.fontSize,
  });

  final String initials;
  final Color color;
  final double size;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize ?? size * 0.38,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

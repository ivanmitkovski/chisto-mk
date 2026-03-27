import 'dart:io';

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
    this.localImagePath,
  });

  final String name;
  final double size;
  final double? fontSize;
  final String? imageUrl;

  /// On-device image (e.g. pending avatar upload). Takes precedence over [imageUrl].
  final String? localImagePath;

  @override
  Widget build(BuildContext context) {
    final String initials = _initials(name);

    final String? path = localImagePath?.trim();
    if (path != null && path.isNotEmpty) {
      final File file = File(path);
      if (file.existsSync()) {
        return ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InitialsCircle(
                initials: initials,
                size: size,
                fontSize: fontSize,
              ),
            ),
          ),
        );
      }
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder:
                (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
                  if (loadingProgress == null) return child;
                  return _InitialsCircle(
                    initials: initials,
                    size: size,
                    fontSize: fontSize,
                    showLoadingRing: true,
                  );
                },
            errorBuilder: (_, _, _) => _InitialsCircle(
              initials: initials,
              size: size,
              fontSize: fontSize,
            ),
          ),
        ),
      );
    }

    return _InitialsCircle(
      initials: initials,
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
    required this.size,
    this.fontSize,
    this.showLoadingRing = false,
  });

  final String initials;
  final double size;
  final double? fontSize;
  final bool showLoadingRing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: fontSize ?? size * 0.38,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (showLoadingRing)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size * 0.06,
              color: AppColors.white.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }
}

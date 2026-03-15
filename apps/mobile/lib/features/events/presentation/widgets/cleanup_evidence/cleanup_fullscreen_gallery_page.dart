import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class CleanupFullscreenGalleryPage extends StatelessWidget {
  const CleanupFullscreenGalleryPage({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  final List<String> imagePaths;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: PageController(initialPage: initialIndex.clamp(0, imagePaths.length - 1)),
            itemCount: imagePaths.length,
            itemBuilder: (BuildContext context, int index) {
              final String path = imagePaths[index];
              final ImageProvider provider = path.startsWith('assets/')
                  ? AssetImage(path)
                  : FileImage(File(path)) as ImageProvider;
              return InteractiveViewer(
                child: Center(
                  child: Image(
                    image: provider,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
                      return Icon(
                        CupertinoIcons.photo,
                        size: 48,
                        color: AppColors.white.withValues(alpha: 0.54),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                  color: AppColors.white,
                  iconSize: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

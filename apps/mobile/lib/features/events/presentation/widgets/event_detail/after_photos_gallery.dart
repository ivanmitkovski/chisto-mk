import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/detail_section_header.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class AfterPhotosGallery extends StatelessWidget {
  const AfterPhotosGallery({
    super.key,
    required this.event,
    required this.onImageTap,
  });

  final EcoEvent event;
  final ValueChanged<int> onImageTap;

  static const double _thumbSize = 96;

  @override
  Widget build(BuildContext context) {
    // No images: nothing to show — EventCompletedDetailCallouts handles the
    // organizer's "add photos" prompt separately.
    if (event.afterImagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DetailSectionHeader(context.l10n.eventsAfterCleanupTitle),
        SizedBox(
          height: _thumbSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: event.afterImagePaths.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: AppSpacing.xs),
            itemBuilder: (BuildContext context, int index) {
              final String path = event.afterImagePaths[index];
              final bool isAsset = path.startsWith('assets/');
              final ImageProvider provider =
                  isAsset ? AssetImage(path) : FileImage(File(path)) as ImageProvider;

              return Semantics(
                button: true,
                label: context.l10n.eventsAfterPhotoSemantic(
                  index + 1,
                  event.afterImagePaths.length,
                ),
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.tap();
                    onImageTap(index);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image(
                      image: provider,
                      width: _thumbSize,
                      height: _thumbSize,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (BuildContext context, Object error, StackTrace? stack) {
                        return Container(
                          width: _thumbSize,
                          height: _thumbSize,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            CupertinoIcons.photo,
                            size: 28,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FullscreenGalleryPage extends StatefulWidget {
  const FullscreenGalleryPage({
    super.key,
    required this.event,
    required this.initialIndex,
  });

  final EcoEvent event;
  final int initialIndex;

  @override
  State<FullscreenGalleryPage> createState() => _FullscreenGalleryPageState();
}

class _FullscreenGalleryPageState extends State<FullscreenGalleryPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.event.afterImagePaths.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (int index) => setState(() => _currentIndex = index),
            itemBuilder: (BuildContext context, int index) {
              final String path = widget.event.afterImagePaths[index];
              final bool isAsset = path.startsWith('assets/');
              final ImageProvider provider =
                  isAsset ? AssetImage(path) : FileImage(File(path)) as ImageProvider;
              return InteractiveViewer(
                child: Center(
                  child: Image(
                    image: provider,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
                      return const Icon(
                        CupertinoIcons.photo,
                        size: 48,
                        color: Colors.white54,
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: context.l10n.commonClose,
                    onPressed: () {
                      AppHaptics.tap();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    color: Colors.white,
                    iconSize: 28,
                  ),
                  const Spacer(),
                  if (total > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.radius10, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

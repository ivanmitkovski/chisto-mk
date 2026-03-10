import 'dart:io';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:flutter/material.dart';

class EvidenceCarousel extends StatefulWidget {
  const EvidenceCarousel({
    super.key,
    required this.photoPaths,
  });

  final List<String> photoPaths;

  @override
  State<EvidenceCarousel> createState() => _EvidenceCarouselState();
}

class _EvidenceCarouselState extends State<EvidenceCarousel> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> existingPhotos = widget.photoPaths
        .where((String path) => File(path).existsSync())
        .toList();
    if (existingPhotos.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22),
        ),
      );
    }

    final int count = existingPhotos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (int index) {
                if (index != _currentIndex) {
                  setState(() => _currentIndex = index);
                  AppHaptics.light();
                }
              },
              itemCount: count,
              itemBuilder: (BuildContext context, int index) {
                return Semantics(
                  label: 'Evidence photo ${index + 1} of $count',
                  image: true,
                  child: AppSmartImage(
                    image: FileImage(File(existingPhotos[index])),
                  ),
                );
              },
            ),
          ),
        ),
        if (count > 1) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(count, (int index) {
              final bool isActive = index == _currentIndex;
              return AnimatedContainer(
                duration: AppMotion.fast,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.divider.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}


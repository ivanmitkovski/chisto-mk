import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';

class MapErrorOverlay extends StatelessWidget {
  const MapErrorOverlay({
    super.key,
    required this.loadError,
    required this.onRetry,
    this.retryFootnote,
  });

  final AppError loadError;
  final VoidCallback onRetry;
  final String? retryFootnote;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.panelBackground,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: AppErrorView(
            error: loadError,
            onRetry: onRetry,
            retryFootnote: retryFootnote,
          ),
        ),
      ),
    );
  }
}

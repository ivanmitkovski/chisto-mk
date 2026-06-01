import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

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

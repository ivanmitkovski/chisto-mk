import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Modal sheet when report detail cannot be loaded and no cached content exists.
class ReportOfflineErrorSheet extends StatelessWidget {
  const ReportOfflineErrorSheet({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final AppError error;
  final VoidCallback onRetry;

  static Future<void> show({
    required BuildContext context,
    required AppError error,
    required VoidCallback onRetry,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext sheetContext) {
        return ReportOfflineErrorSheet(error: error, onRetry: onRetry);
      },
    );
  }

  bool get _useOfflineCopy =>
      error.code == 'NETWORK_ERROR' || error.code == 'TIMEOUT';

  @override
  Widget build(BuildContext context) {
    final String title = _useOfflineCopy
        ? context.l10n.offlineConnectionTitle
        : localizedAppErrorMessage(context.l10n, error);
    final String? subtitle = _useOfflineCopy
        ? context.l10n.offlineConnectionBody
        : localizedAppErrorDetailMessage(context.l10n, error);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: AppEmptyState(
          icon: Icons.cloud_off_rounded,
          iconVariant: AppEmptyStateIconVariant.standard,
          title: title,
          subtitle: subtitle,
          action: error.retryable
              ? AppButton.primary(
                  label: context.l10n.commonTryAgain,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    onRetry();
                  },
                  leadingIcon: const Icon(Icons.refresh_rounded, size: 20),
                )
              : null,
          secondaryAction: AppButton.text(
            label: context.l10n.commonBack,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ),
      ),
    );
  }
}

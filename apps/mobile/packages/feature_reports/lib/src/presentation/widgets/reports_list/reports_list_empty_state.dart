import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ReportsListEmptyState extends StatelessWidget {
  const ReportsListEmptyState({
    super.key,
    required this.onReportPollution,
  });

  final VoidCallback onReportPollution;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.description_outlined,
      title: context.l10n.reportListEmptyTitle,
      subtitle: context.l10n.reportListEmptySubtitle,
      action: Semantics(
        button: true,
        label: context.l10n.reportListFabLabel,
        child: AppButton.primary(
          label: context.l10n.reportListFabLabel,
          onPressed: onReportPollution,
          leadingIcon: const Icon(
            Icons.add_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class ReportsListFilterEmptyState extends StatelessWidget {
  const ReportsListFilterEmptyState({
    super.key,
    required this.message,
    required this.hint,
    required this.icon,
    this.onClearSearch,
    this.clearSearchLabel,
  });

  final String message;
  final String hint;
  final IconData icon;
  final VoidCallback? onClearSearch;
  final String? clearSearchLabel;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: message,
      subtitle: hint,
      secondaryAction: onClearSearch != null && clearSearchLabel != null
          ? AppButton.text(
              label: clearSearchLabel!,
              onPressed: onClearSearch,
            )
          : null,
    );
  }
}

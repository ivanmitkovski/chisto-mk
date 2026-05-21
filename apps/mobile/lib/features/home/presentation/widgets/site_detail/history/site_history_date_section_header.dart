import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Plain section label above a grouped history panel (not pinned).
class SiteHistorySectionLabel extends StatelessWidget {
  const SiteHistorySectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
      ),
    );
  }
}

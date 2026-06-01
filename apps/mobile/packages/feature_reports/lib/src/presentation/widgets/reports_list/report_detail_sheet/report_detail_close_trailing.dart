import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/app_surface_primitives.dart';
import 'package:flutter/material.dart';

/// Close control for [ReportDetailSheet] with optional refresh/sync affordance.
class ReportDetailCloseTrailing extends StatelessWidget {
  const ReportDetailCloseTrailing({
    super.key,
    required this.isRefreshing,
    required this.semanticLabel,
  });

  final bool isRefreshing;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppCircleIconButton(
      icon: Icons.close_rounded,
      semanticLabel: semanticLabel,
      isLoading: isRefreshing,
      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
    );
  }
}

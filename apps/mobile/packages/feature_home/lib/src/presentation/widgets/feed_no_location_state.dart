import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class FeedNoLocationState extends StatelessWidget {
  const FeedNoLocationState({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.location_off_rounded,
      title: context.l10n.feedNoLocationTitle,
      subtitle: context.l10n.feedNoLocationHint,
      action: AppButton.primary(
        label: context.l10n.feedNoLocationOpenSettings,
        onPressed: onOpenSettings,
        expand: false,
      ),
    );
  }
}

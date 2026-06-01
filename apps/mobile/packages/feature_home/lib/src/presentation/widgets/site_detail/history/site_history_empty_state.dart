import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_empty_state.dart';
import 'package:flutter/material.dart';

class SiteHistoryEmptyState extends StatelessWidget {
  const SiteHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.history_rounded,
      title: context.l10n.siteHistoryEmptyTitle,
      subtitle: context.l10n.siteHistoryEmptyMessage,
    );
  }
}

import 'package:design_system/design_system.dart';
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
        style: AppTypographySurfaces.homeHistoryStatusCaption(
          Theme.of(context).textTheme,
        ),
      ),
    );
  }
}

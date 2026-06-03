import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class WeeklyRankingsEmpty extends StatelessWidget {
  const WeeklyRankingsEmpty({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.emoji_events_outlined,
      title: title,
      subtitle: subtitle,
    );
  }
}

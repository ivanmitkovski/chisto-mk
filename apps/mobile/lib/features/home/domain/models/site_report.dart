import 'package:flutter/material.dart';

class SiteReport {
  const SiteReport({
    required this.id,
    required this.reporterName,
    required this.reportedAt,
    required this.description,
    this.images = const [],
  });

  final String id;
  final String reporterName;
  final DateTime reportedAt;
  final String description;
  final List<ImageProvider> images;

  String get reportedAgo {
    final Duration diff = DateTime.now().difference(reportedAt);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'Just now';
  }
}

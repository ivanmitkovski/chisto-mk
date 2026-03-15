import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum SiteReportReason {
  fakeData('Fake or misleading data', 'Information does not reflect reality', CupertinoIcons.exclamationmark_triangle_fill),
  alreadyReported('Already resolved', 'Issue was cleaned or fixed', Icons.check_circle_outline_rounded),
  wrongLocation('Wrong location', 'Site is placed incorrectly on the map', Icons.location_off_rounded),
  duplicate('Duplicate report', 'Same site reported multiple times', Icons.copy_rounded),
  spam('Spam or abuse', 'Inappropriate or malicious content', Icons.report_rounded),
  other('Other', 'Something else is wrong', Icons.more_horiz_rounded);

  const SiteReportReason(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
  final IconData icon;
}

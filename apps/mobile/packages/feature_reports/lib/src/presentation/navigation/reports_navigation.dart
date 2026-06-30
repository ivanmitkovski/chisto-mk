import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Full-screen navigation for reports while the user is inside [HomeShell].
class ReportsNavigation {
  const ReportsNavigation._();

  static Future<T?> pushNewReportScreen<T extends Object?>(
    BuildContext context, {
    XFile? initialPhoto,
    String? entryLabel,
    String? entryHint,
  }) {
    return AppNavigation.pushNewReportWizard(
          initialPhoto: initialPhoto,
          entryLabel: entryLabel,
          entryHint: entryHint,
        )
        as Future<T?>;
  }
}

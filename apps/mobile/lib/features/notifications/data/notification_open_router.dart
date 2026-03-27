import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';

class NotificationOpenRouter {
  const NotificationOpenRouter._();

  static void handleOpen(BuildContext context, RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    final String? type = data['type'] as String?;
    final String? siteId = data['siteId'] as String?;

    if (siteId != null && siteId.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.home,
        arguments: 0,
      );
      return;
    }

    switch (type) {
      case 'REPORT_STATUS':
      case 'SITE_UPDATE':
      case 'UPVOTE':
      case 'COMMENT':
      case 'NEARBY_REPORT':
        Navigator.of(context).pushNamed(
          AppRoutes.home,
          arguments: 0,
        );
        return;
      case 'CLEANUP_EVENT':
        Navigator.of(context).pushNamed(AppRoutes.homeEvents);
        return;
      default:
        Navigator.of(context).pushNamed(
          AppRoutes.home,
          arguments: 0,
        );
    }
  }

  static void handleOpenFromData(BuildContext context, Map<String, dynamic> data) {
    final String? type = data['type'] as String?;

    switch (type) {
      case 'CLEANUP_EVENT':
        Navigator.of(context).pushNamed(AppRoutes.homeEvents);
        return;
      default:
        Navigator.of(context).pushNamed(
          AppRoutes.home,
          arguments: 0,
        );
    }
  }
}

import 'package:flutter/material.dart';

/// Best-effort image warm-up that never throws to the Flutter error zone.
///
/// Presigned S3 URLs may return 403 when expired; callers should rely on
/// [CachedNetworkImage] / gallery widgets to refresh with a new URL.
Future<void> safePrecacheImage(
  ImageProvider provider,
  BuildContext context,
) async {
  if (!context.mounted) {
    return;
  }
  try {
    await precacheImage(provider, context);
  } catch (_) {
    // Ignore — warm-up is optional.
  }
}

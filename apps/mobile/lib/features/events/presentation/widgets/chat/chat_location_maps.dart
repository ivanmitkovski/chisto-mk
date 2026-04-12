import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Uri chatLocationDirectionsUri(double lat, double lng) {
  if (kIsWeb) {
    return Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
    default:
      return Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
  }
}

Future<void> openChatLocationInMaps(
  BuildContext context,
  double lat,
  double lng,
) async {
  final Uri uri = chatLocationDirectionsUri(lat, lng);
  try {
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnack.show(context, message: context.l10n.eventChatOpenMapsFailed);
    }
  } on Object {
    if (context.mounted) {
      AppSnack.show(context, message: context.l10n.eventChatOpenMapsFailed);
    }
  }
}

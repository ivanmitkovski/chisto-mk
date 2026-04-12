import 'dart:async' show unawaited;

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/utils/cached_tile_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_location_maps.dart';

Future<void> openChatLocationFullscreen(
  BuildContext context, {
  required double lat,
  required double lng,
  String? label,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext ctx) => ChatLocationFullscreenScreen(
        lat: lat,
        lng: lng,
        label: label,
      ),
    ),
  );
}

class ChatLocationFullscreenScreen extends StatelessWidget {
  const ChatLocationFullscreenScreen({
    super.key,
    required this.lat,
    required this.lng,
    this.label,
  });

  final double lat;
  final double lng;
  final String? label;

  static final LatLngBounds _cameraBounds = LatLngBounds(
    LatLng(ReportGeoFence.minLat, ReportGeoFence.minLng),
    LatLng(ReportGeoFence.maxLat, ReportGeoFence.maxLng),
  );

  @override
  Widget build(BuildContext context) {
    final LatLng point = LatLng(lat, lng);
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final bool highDpi = dpr > 1.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.eventChatLocationMapTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15,
                  minZoom: 3,
                  maxZoom: 18,
                  backgroundColor: AppColors.mapLightPaper,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  cameraConstraint: CameraConstraint.containCenter(bounds: _cameraBounds),
                ),
                children: <Widget>[
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const <String>['a', 'b', 'c', 'd'],
                    maxNativeZoom: 20,
                    userAgentPackageName: 'chisto_mobile',
                    retinaMode: highDpi,
                    keepBuffer: 2,
                    panBuffer: 1,
                    tileProvider: createCachedTileProvider(maxStaleDays: 30),
                    tileDisplay: const TileDisplay.fadeIn(
                      duration: Duration(milliseconds: 220),
                      startOpacity: 0,
                    ),
                  ),
                  MarkerLayer(
                    markers: <Marker>[
                      Marker(
                        point: point,
                        width: 40,
                        height: 48,
                        alignment: Alignment.topCenter,
                        child: Icon(
                          CupertinoIcons.location_solid,
                          size: 34,
                          color: AppColors.accentDanger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (label != null && label!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  label!.trim(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        AppHaptics.light();
                        await Clipboard.setData(ClipboardData(text: '$lat,$lng'));
                        if (context.mounted) {
                          AppSnack.show(context, message: context.l10n.eventChatCopied);
                        }
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(context.l10n.eventChatCopyCoordinates),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        AppHaptics.light();
                        unawaited(openChatLocationInMaps(context, lat, lng));
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: Text(context.l10n.eventChatDirections),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

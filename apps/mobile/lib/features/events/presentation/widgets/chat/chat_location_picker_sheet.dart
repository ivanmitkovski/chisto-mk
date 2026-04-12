import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/position.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/cached_tile_provider.dart';

class ChatLocationPickerSheet extends StatefulWidget {
  const ChatLocationPickerSheet({super.key});

  @override
  State<ChatLocationPickerSheet> createState() => _ChatLocationPickerSheetState();
}

class _ChatLocationPickerSheetState extends State<ChatLocationPickerSheet>
    with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    curve: Curves.easeOutCubic,
  );

  LatLng _center = const LatLng(41.9981, 21.4254);
  String? _label;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng loc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      _animatedMapController.animateTo(dest: loc, zoom: 16);
      setState(() {
        _center = loc;
        _locating = false;
      });
      _reverseGeocode(loc);
    } on Object catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _reverseGeocode(LatLng loc) async {
    try {
      final List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final geo.Placemark p = placemarks.first;
        final List<String> parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        setState(() => _label = parts.join(', '));
      }
    } on Object catch (_) {}
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (hasGesture && position.center != null) {
      setState(() {
        _center = position.center!;
        _label = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final bool highDpi = MediaQuery.devicePixelRatioOf(context) > 1.3;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: <Widget>[
            Center(
              child: Container(
                width: AppSpacing.sheetHandle,
                height: AppSpacing.sheetHandleHeight,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Share Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  FlutterMap(
                    mapController: _animatedMapController.mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 15,
                      onPositionChanged: _onMapPositionChanged,
                      onMapEvent: (MapEvent event) {
                        if (event is MapEventMoveEnd) {
                          _reverseGeocode(_center);
                        }
                      },
                    ),
                    children: <Widget>[
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const <String>['a', 'b', 'c', 'd'],
                        maxNativeZoom: 20,
                        userAgentPackageName: 'chisto_mobile',
                        retinaMode: highDpi,
                        keepBuffer: 3,
                        panBuffer: 2,
                        tileProvider: createCachedTileProvider(maxStaleDays: 30),
                        tileDisplay: const TileDisplay.fadeIn(
                          duration: Duration(milliseconds: 220),
                          startOpacity: 0,
                        ),
                      ),
                      MarkerLayer(
                        markers: <Marker>[
                          Marker(
                            point: _center,
                            width: 42,
                            height: 42,
                            alignment: Alignment.topCenter,
                            child: Icon(
                              CupertinoIcons.location_solid,
                              size: 42,
                              color: AppColors.primary,
                              shadows: const <Shadow>[
                                Shadow(blurRadius: 8, color: Colors.black26),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: AppSpacing.md,
                    right: AppSpacing.md,
                    child: FloatingActionButton.small(
                      heroTag: 'chat_loc_picker_fab',
                      backgroundColor: AppColors.appBackground,
                      onPressed: _locating ? null : _goToCurrentLocation,
                      child: _locating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(CupertinoIcons.location_fill, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            if (_label != null && _label!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Row(
                  children: <Widget>[
                    Icon(CupertinoIcons.location, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md + bottomInset,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context, <String, dynamic>{
                      'lat': _center.latitude,
                      'lng': _center.longitude,
                      'label': _label,
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnDark,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  child: Text(context.l10n.eventChatSendLocation),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

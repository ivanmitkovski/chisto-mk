import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/location/location_service.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker/location_picker_controller.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker/location_picker_view.dart';
import 'package:flutter/material.dart';

export 'location_picker/location_picker_controller.dart' show LocationPickerResult;

/// Map-based location step; delegates state to [LocationPickerController].
class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationChanged,
    this.showAdvanceBlockedHint = false,
    this.locationService,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final void Function(LocationPickerResult result) onLocationChanged;
  final bool showAdvanceBlockedHint;

  /// When null, uses [ServiceLocator.instance.locationService] (app wiring).
  final LocationService? locationService;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final LocationPickerController _controller;

  @override
  void initState() {
    super.initState();
    final LocationService svc =
        widget.locationService ?? ServiceLocator.instance.locationService;
    _controller = LocationPickerController(
      locationService: svc,
      onLocationChanged: widget.onLocationChanged,
      initialLatitude: widget.initialLatitude,
      initialLongitude: widget.initialLongitude,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.startInitialFlow();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, _) {
        return LocationPickerView(
          controller: _controller,
          showAdvanceBlockedHint: widget.showAdvanceBlockedHint,
        );
      },
    );
  }
}

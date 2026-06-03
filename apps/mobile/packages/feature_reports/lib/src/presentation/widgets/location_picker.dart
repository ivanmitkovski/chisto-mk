import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_controller.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'location_picker/location_picker_controller.dart'
    show LocationPickerResult;

/// Map-based location step; delegates state to [LocationPickerController].
class LocationPicker extends ConsumerStatefulWidget {
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

  /// When null, uses [locationServiceProvider] via Riverpod (app wiring).
  final LocationService? locationService;

  @override
  ConsumerState<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends ConsumerState<LocationPicker> {
  late final double? _familyInitialLatitude;
  late final double? _familyInitialLongitude;

  LocationPickerControllerProvider get _provider =>
      locationPickerControllerProvider(
        _familyInitialLatitude,
        _familyInitialLongitude,
      );

  @override
  void initState() {
    super.initState();
    _familyInitialLatitude = widget.initialLatitude;
    _familyInitialLongitude = widget.initialLongitude;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncControllerCallbacks();
      ref
          .read(_provider.notifier)
          .startInitialFlow(
            initialLatitude: _familyInitialLatitude,
            initialLongitude: _familyInitialLongitude,
          );
    });
  }

  @override
  void didUpdateWidget(covariant LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onLocationChanged != widget.onLocationChanged ||
        oldWidget.locationService != widget.locationService) {
      _syncControllerCallbacks();
    }
  }

  void _syncControllerCallbacks() {
    final LocationPickerController notifier = ref.read(_provider.notifier);
    notifier.setOnLocationChanged(widget.onLocationChanged);
    if (widget.locationService != null) {
      notifier.setLocationService(widget.locationService!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocationPickerState state = ref.watch(_provider);
    final LocationPickerController notifier = ref.read(_provider.notifier);
    return LocationPickerView(
      state: state,
      notifier: notifier,
      showAdvanceBlockedHint: widget.showAdvanceBlockedHint,
    );
  }
}

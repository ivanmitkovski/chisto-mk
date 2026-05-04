import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker.dart';
import 'package:flutter/material.dart';

/// Location step: map picker with Macedonia bounds UX.
class NewReportLocationStageBody extends StatelessWidget {
  const NewReportLocationStageBody({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onLocationChanged,
    required this.showAdvanceBlockedHint,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final ValueChanged<LocationPickerResult> onLocationChanged;
  final bool showAdvanceBlockedHint;

  @override
  Widget build(BuildContext context) {
    return LocationPicker(
      initialLatitude: initialLatitude,
      initialLongitude: initialLongitude,
      onLocationChanged: onLocationChanged,
      showAdvanceBlockedHint: showAdvanceBlockedHint,
    );
  }
}

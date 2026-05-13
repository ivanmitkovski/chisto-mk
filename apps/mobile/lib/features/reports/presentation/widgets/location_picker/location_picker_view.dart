import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/theme/report_tokens.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker/location_picker_controller.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker/location_picker_geo_utils.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/location_picker/location_picker_map_stack.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:latlong2/latlong.dart';

/// Map + status UI for the report location step; state lives on [LocationPickerController].
class LocationPickerView extends StatelessWidget {
  const LocationPickerView({
    super.key,
    required this.controller,
    required this.showAdvanceBlockedHint,
  });

  final LocationPickerController controller;
  final bool showAdvanceBlockedHint;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final LatLng center =
        controller.currentCenter ?? locationPickerMacedoniaCenter();
    final double zoom =
        controller.currentCenter != null ? controller.currentZoom : 7;
    final bool hasConfirmedLocation =
        controller.confirmedCenter != null &&
        locationPickerSameLatLng(controller.currentCenter, controller.confirmedCenter) &&
        !controller.needsConfirmation;
    final bool apiSaysOutsideMacedonia =
        controller.lastGeocodedCenter != null &&
        controller.currentCenter != null &&
        locationPickerSameLatLng(
          controller.currentCenter,
          controller.lastGeocodedCenter,
        ) &&
        !controller.lastGeocodeWasMacedonia;
    final String stateLabel = controller.permissionUnavailable
        ? l10n.locationPickerStatePermissionNeeded
        : controller.resolvingGps && controller.currentCenter == null
        ? l10n.locationPickerStateDetectingPosition
        : controller.geocodingInProgress
        ? l10n.locationPickerStateCheckingLocation
        : controller.gpsOutsideCoverage
        ? l10n.locationPickerStateCurrentLocationUnavailable
        : controller.gpsNeedsReview
        ? l10n.locationPickerStateReviewDetectedLocation
        : apiSaysOutsideMacedonia
        ? l10n.locationPickerStateOutsideMacedonia
        : controller.needsConfirmation
        ? l10n.locationPickerStatePinNeedsConfirmation
        : hasConfirmedLocation
        ? l10n.locationPickerStateLocationConfirmed
        : l10n.locationPickerStateTapConfirmWhenReady;

    return Semantics(
      label: l10n.locationPickerScreenSemantics(stateLabel),
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            sortKey: const OrdinalSortKey(0),
            label: l10n.locationPickerMapSemantics,
            child: LocationPickerMapStack(
              mapController: controller.mapController,
              center: center,
              zoom: zoom,
              macedoniaBounds: LocationPickerController.macedoniaBounds,
              onPositionChanged: controller.onMapMoved,
              hasConfirmedLocation: hasConfirmedLocation,
              showGpsResolvingOverlay:
                  controller.resolvingGps && controller.currentCenter == null,
              useCurrentLocationButton: _buildUseCurrentLocationButton(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatusSection(
            context: context,
            l10n: l10n,
            stateLabel: stateLabel,
            hasConfirmedLocation: hasConfirmedLocation,
            showAdvanceBlockedHint: showAdvanceBlockedHint,
            apiSaysOutsideMacedonia: apiSaysOutsideMacedonia,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required String stateLabel,
    required bool hasConfirmedLocation,
    required bool showAdvanceBlockedHint,
    required bool apiSaysOutsideMacedonia,
  }) {
    final bool showConfirmAction =
        controller.currentCenter != null &&
        (controller.needsConfirmation || !hasConfirmedLocation) &&
        controller.currentPositionIsInMacedoniaByApi;

    return Semantics(
      sortKey: const OrdinalSortKey(1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showAdvanceBlockedHint) ...<Widget>[
            ReportInfoBanner(
              icon: Icons.place_outlined,
              tone: ReportSurfaceTone.warning,
              message: context.l10n.reportLocationAdvanceBlockedBanner,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Semantics(
            liveRegion: true,
            label: stateLabel,
            child: ReportStatePill(
              label: stateLabel,
              tone: hasConfirmedLocation
                  ? ReportSurfaceTone.success
                  : controller.gpsOutsideCoverage
                  ? ReportSurfaceTone.warning
                  : controller.lastGeocodedCenter != null &&
                        controller.currentCenter != null &&
                        locationPickerSameLatLng(
                          controller.currentCenter,
                          controller.lastGeocodedCenter,
                        ) &&
                        !controller.lastGeocodeWasMacedonia
                  ? ReportSurfaceTone.danger
                  : controller.needsConfirmation
                  ? ReportSurfaceTone.warning
                  : ReportSurfaceTone.neutral,
              icon: hasConfirmedLocation
                  ? Icons.check_circle_outline
                  : controller.gpsOutsideCoverage
                  ? Icons.gps_not_fixed_rounded
                  : controller.lastGeocodedCenter != null &&
                        controller.currentCenter != null &&
                        locationPickerSameLatLng(
                          controller.currentCenter,
                          controller.lastGeocodedCenter,
                        ) &&
                        !controller.lastGeocodeWasMacedonia
                  ? Icons.location_off_outlined
                  : Icons.place_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            controller.gpsNeedsReview
                ? l10n.locationPickerHelperReviewGps
                : controller.lastGeocodedCenter != null &&
                      controller.currentCenter != null &&
                      locationPickerSameLatLng(
                        controller.currentCenter,
                        controller.lastGeocodedCenter,
                      ) &&
                      !controller.lastGeocodeWasMacedonia
                ? context.l10n.reportFlowLocationOutsideMacedoniaHelper
                : hasConfirmedLocation
                ? l10n.locationPickerHelperReadyToSubmit
                : l10n.locationPickerHelperMovePinConfirm,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (controller.geocodingInProgress || controller.address != null) ...<Widget>[
            _buildAddressBadge(context, l10n),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (controller.locationLookupFailed &&
              controller.currentCenter != null &&
              !controller.geocodingInProgress)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Semantics(
                    button: true,
                    label: context.l10n.locationRetryAddressSemantic,
                    hint: l10n.locationPickerRetryAddressHint,
                    child: TextButton.icon(
                      onPressed: controller.retryGeocode,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(context.l10n.locationRetryAddressSemantic),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  if (controller.geocodeRetryCount >= 2)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        l10n.locationPickerAddressLookupUnavailableBody,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (controller.permissionUnavailable) ...<Widget>[
            ReportInfoBanner(
              icon: Icons.location_disabled_outlined,
              tone: ReportSurfaceTone.neutral,
              message: l10n.locationPickerBannerPermissionOff,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (controller.gpsOutsideCoverage) ...<Widget>[
            ReportInfoBanner(
              icon: Icons.public_off_outlined,
              tone: ReportSurfaceTone.warning,
              title: l10n.locationPickerBannerGpsOutsideTitle,
              message: l10n.locationPickerBannerGpsOutsideBody,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (showConfirmAction) const SizedBox(height: AppSpacing.md),
          if (showConfirmAction)
            Semantics(
              button: true,
              enabled: !controller.geocodingInProgress,
              label: hasConfirmedLocation
                  ? l10n.locationPickerConfirmSemanticsWhenConfirmed
                  : l10n.locationPickerConfirmSemanticsWhenUnset,
              hint: hasConfirmedLocation
                  ? l10n.locationPickerConfirmHintDone
                  : l10n.locationPickerConfirmHintPending,
              child: GestureDetector(
                onTapDown: controller.geocodingInProgress
                    ? null
                    : (_) => controller.setConfirmButtonPressed(true),
                onTapUp: (_) => controller.setConfirmButtonPressed(false),
                onTapCancel: () => controller.setConfirmButtonPressed(false),
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: controller.confirmButtonPressed ? 0.98 : 1.0,
                  duration: AppMotion.xFast,
                  curve: AppMotion.standardCurve,
                  child: SizedBox(
                    height: ReportTokens.locationConfirmButtonHeight,
                    child: FilledButton.icon(
                      onPressed: controller.geocodingInProgress
                          ? null
                          : () {
                              AppHaptics.tap();
                              controller.confirmSelection(fromUser: true);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnDark,
                        disabledBackgroundColor: AppColors.reportDisabledPrimaryFill,
                        disabledForegroundColor: AppColors.textOnDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                      ),
                      icon: controller.geocodingInProgress
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnDark,
                              ),
                            )
                          : Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: AppColors.textOnDark,
                            ),
                      label: Text(
                        controller.geocodingInProgress
                            ? l10n.locationPickerConfirmChecking
                            : l10n.locationPickerConfirmLocation,
                        style: AppTypography.buttonLabel.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressBadge(BuildContext context, AppLocalizations l10n) {
    final bool checking = controller.geocodingInProgress;
    final String displayText = checking
        ? l10n.locationPickerAddressChecking
        : controller.locationLookupFailed
        ? l10n.locationPickerAddressUnavailableWithCoords(
            controller.address ?? '',
          )
        : controller.gpsNeedsReview
        ? l10n.locationPickerAddressNear(controller.address ?? '')
        : controller.address ?? l10n.locationPickerAddressPlaceholder;
    return AnimatedSwitcher(
      duration: AppMotion.xFast,
      switchInCurve: AppMotion.standardCurve,
      switchOutCurve: AppMotion.standardCurve,
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey<String>(displayText),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.reportDividerStrong),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              checking ? Icons.schedule_rounded : Icons.location_on_outlined,
              size: 16,
              color: checking ? AppColors.textMuted : AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.reportsLocationAddressBadge(
                  Theme.of(context).textTheme,
                ).copyWith(
                  color: checking ? AppColors.textMuted : AppColors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUseCurrentLocationButton(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Semantics(
      button: true,
      label: l10n.locationPickerUseCurrentLocationLabel,
      hint: l10n.locationPickerUseCurrentLocationHint,
      child: GestureDetector(
        onTapDown: controller.resolvingGps
            ? null
            : (_) => controller.setUseLocationButtonPressed(true),
        onTapUp: (_) => controller.setUseLocationButtonPressed(false),
        onTapCancel: () => controller.setUseLocationButtonPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: controller.useLocationButtonPressed ? 0.98 : 1.0,
          duration: AppMotion.xFast,
          curve: AppMotion.standardCurve,
          child: Container(
            width: ReportTokens.locationGpsButtonSize,
            height: ReportTokens.locationGpsButtonSize,
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                onTap: () {
                  AppHaptics.light();
                  controller.detectCurrentLocation();
                },
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: controller.resolvingGps
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryDark,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          size: 20,
                          color: AppColors.primaryDark,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

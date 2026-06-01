import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/presentation/theme/report_tokens.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_controller.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_geo_utils.dart';
import 'package:feature_reports/src/presentation/widgets/location_picker/location_picker_map_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:latlong2/latlong.dart';

/// Map + status UI for the report location step; state lives on [LocationPickerController].
class LocationPickerView extends StatelessWidget {
  const LocationPickerView({
    super.key,
    required this.state,
    required this.notifier,
    required this.showAdvanceBlockedHint,
  });

  final LocationPickerState state;
  final LocationPickerController notifier;
  final bool showAdvanceBlockedHint;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final LatLng center =
        state.currentCenter ?? locationPickerMacedoniaCenter();
    final double zoom = state.currentCenter != null ? state.currentZoom : 7;
    final bool hasConfirmedLocation =
        state.confirmedCenter != null &&
        locationPickerSameLatLng(state.currentCenter, state.confirmedCenter) &&
        !state.needsConfirmation;
    final bool apiSaysOutsideMacedonia =
        state.lastGeocodedCenter != null &&
        state.currentCenter != null &&
        locationPickerSameLatLng(
          state.currentCenter,
          state.lastGeocodedCenter,
        ) &&
        !state.lastGeocodeWasMacedonia;
    final String stateLabel = state.permissionUnavailable
        ? l10n.locationPickerStatePermissionNeeded
        : state.resolvingGps && state.currentCenter == null
        ? l10n.locationPickerStateDetectingPosition
        : state.geocodingInProgress
        ? l10n.locationPickerStateCheckingLocation
        : state.gpsOutsideCoverage
        ? l10n.locationPickerStateCurrentLocationUnavailable
        : state.gpsNeedsReview
        ? l10n.locationPickerStateReviewDetectedLocation
        : apiSaysOutsideMacedonia
        ? l10n.locationPickerStateOutsideMacedonia
        : state.needsConfirmation
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
              mapController: notifier.mapController,
              center: center,
              zoom: zoom,
              macedoniaBounds: LocationPickerController.macedoniaBounds,
              onPositionChanged: notifier.onMapMoved,
              hasConfirmedLocation: hasConfirmedLocation,
              showGpsResolvingOverlay:
                  state.resolvingGps && state.currentCenter == null,
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool showConfirmAction =
        state.currentCenter != null &&
        (state.needsConfirmation || !hasConfirmedLocation) &&
        state.currentPositionIsInMacedoniaByApi;

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
                  : state.gpsOutsideCoverage
                  ? ReportSurfaceTone.warning
                  : state.lastGeocodedCenter != null &&
                        state.currentCenter != null &&
                        locationPickerSameLatLng(
                          state.currentCenter,
                          state.lastGeocodedCenter,
                        ) &&
                        !state.lastGeocodeWasMacedonia
                  ? ReportSurfaceTone.danger
                  : state.needsConfirmation
                  ? ReportSurfaceTone.warning
                  : ReportSurfaceTone.neutral,
              icon: hasConfirmedLocation
                  ? Icons.check_circle_outline
                  : state.gpsOutsideCoverage
                  ? Icons.gps_not_fixed_rounded
                  : state.lastGeocodedCenter != null &&
                        state.currentCenter != null &&
                        locationPickerSameLatLng(
                          state.currentCenter,
                          state.lastGeocodedCenter,
                        ) &&
                        !state.lastGeocodeWasMacedonia
                  ? Icons.location_off_outlined
                  : Icons.place_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.gpsNeedsReview
                ? l10n.locationPickerHelperReviewGps
                : state.lastGeocodedCenter != null &&
                      state.currentCenter != null &&
                      locationPickerSameLatLng(
                        state.currentCenter,
                        state.lastGeocodedCenter,
                      ) &&
                      !state.lastGeocodeWasMacedonia
                ? context.l10n.reportFlowLocationOutsideMacedoniaHelper
                : hasConfirmedLocation
                ? l10n.locationPickerHelperReadyToSubmit
                : l10n.locationPickerHelperMovePinConfirm,
            style: AppTypographySurfaces.reportsLocationPickerHint(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.geocodingInProgress || state.address != null) ...<Widget>[
            _buildAddressBadge(context, l10n),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (state.locationLookupFailed &&
              state.currentCenter != null &&
              !state.geocodingInProgress)
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
                      onPressed: notifier.retryGeocode,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(context.l10n.locationRetryAddressSemantic),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  if (state.geocodeRetryCount >= 2)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        l10n.locationPickerAddressLookupUnavailableBody,
                        style: AppTypographySurfaces.reportsLocationPickerHint(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (state.permissionUnavailable) ...<Widget>[
            ReportInfoBanner(
              icon: Icons.location_disabled_outlined,
              tone: ReportSurfaceTone.neutral,
              message: l10n.locationPickerBannerPermissionOff,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (state.gpsOutsideCoverage) ...<Widget>[
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
              enabled: !state.geocodingInProgress,
              label: hasConfirmedLocation
                  ? l10n.locationPickerConfirmSemanticsWhenConfirmed
                  : l10n.locationPickerConfirmSemanticsWhenUnset,
              hint: hasConfirmedLocation
                  ? l10n.locationPickerConfirmHintDone
                  : l10n.locationPickerConfirmHintPending,
              child: GestureDetector(
                onTapDown: state.geocodingInProgress
                    ? null
                    : (_) => notifier.setConfirmButtonPressed(pressed: true),
                onTapUp: (_) =>
                    notifier.setConfirmButtonPressed(pressed: false),
                onTapCancel: () =>
                    notifier.setConfirmButtonPressed(pressed: false),
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: state.confirmButtonPressed ? 0.98 : 1.0,
                  duration: AppMotion.xFast,
                  curve: AppMotion.standardCurve,
                  child: SizedBox(
                    height: ReportTokens.locationConfirmButtonHeight,
                    child: FilledButton.icon(
                      onPressed: state.geocodingInProgress
                          ? null
                          : () {
                              notifier.confirmSelection(fromUser: true);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnDark,
                        disabledBackgroundColor:
                            AppColors.reportDisabledPrimaryFill,
                        disabledForegroundColor: AppColors.textOnDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                      ),
                      icon: state.geocodingInProgress
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: AppLoadingIndicator(
                                size: AppLoadingIndicatorSize.sm,
                                color: AppColors.textOnDark,
                              ),
                            )
                          : const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: AppColors.textOnDark,
                            ),
                      label: Text(
                        state.geocodingInProgress
                            ? l10n.locationPickerConfirmChecking
                            : l10n.locationPickerConfirmLocation,
                        style: AppTypography.buttonLabel(
                          textTheme,
                        ).copyWith(color: AppColors.textOnDark),
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
    final bool checking = state.geocodingInProgress;
    final String displayText = checking
        ? l10n.locationPickerAddressChecking
        : state.locationLookupFailed
        ? l10n.locationPickerAddressUnavailableWithCoords(state.address ?? '')
        : state.gpsNeedsReview
        ? l10n.locationPickerAddressNear(state.address ?? '')
        : state.address ?? l10n.locationPickerAddressPlaceholder;
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
                style:
                    AppTypographySurfaces.reportsLocationAddressBadge(
                      Theme.of(context).textTheme,
                    ).copyWith(
                      color: checking
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
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
        onTapDown: state.resolvingGps
            ? null
            : (_) => notifier.setUseLocationButtonPressed(pressed: true),
        onTapUp: (_) => notifier.setUseLocationButtonPressed(pressed: false),
        onTapCancel: () => notifier.setUseLocationButtonPressed(pressed: false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: state.useLocationButtonPressed ? 0.98 : 1.0,
          duration: AppMotion.xFast,
          curve: AppMotion.standardCurve,
          child: Container(
            width: ReportTokens.locationGpsButtonSize,
            height: ReportTokens.locationGpsButtonSize,
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: AppShadows.locationPickerFab(),
            ),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                onTap: notifier.detectCurrentLocation,
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: state.resolvingGps
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: AppLoadingIndicator(
                            size: AppLoadingIndicatorSize.sm,
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

import 'dart:async';

import 'package:chisto_infrastructure/core/deep_links/deep_link_router.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/location/device_location_reader.dart';
import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/location/macedonia_bounds.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/utils/cached_tile_provider.dart';
import 'package:chisto_infrastructure/shared/widgets/widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/home_location_controller.dart';
import 'package:feature_auth/src/presentation/constants/auth_error_messages.dart';
import 'package:feature_auth/src/presentation/utils/location_permission_ui.dart';
import 'package:feature_auth/src/presentation/widgets/auth_form_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

enum _LocationGateBlock { none, outsideMacedonia, unavailable }

/// Shown after OTP verification in the sign-up flow (and on launch when home
/// location is missing). Users must confirm an in-Macedonia GPS fix to enter the app.
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key, this.tileProviderOverride});

  final TileProvider? tileProviderOverride;

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  String? _currentAddress;
  bool _detecting = false;
  _LocationGateBlock _block = _LocationGateBlock.none;

  final LatLng _mapCenter = const LatLng(41.6086, 21.7453);
  LatLng? _selectedPosition;
  final MapController _mapController = MapController();
  bool _showTileLoadingOverlay = true;
  Timer? _tileLoadingTimer;

  @override
  void initState() {
    super.initState();
    _tileLoadingTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showTileLoadingOverlay = false);
    });
  }

  @override
  void dispose() {
    _tileLoadingTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _confirmLocation() async {
    if (_detecting) return;
    setState(() {
      _detecting = true;
      _block = _LocationGateBlock.none;
    });

    final LocationService location = ref
        .read(appBootstrapProvider)
        .locationService;
    final bool permissionOk = await ensureLocationPermissionForGate(
      context: context,
      location: location,
    );
    if (!permissionOk || !mounted) {
      setState(() {
        _detecting = false;
        _block = _LocationGateBlock.unavailable;
      });
      return;
    }

    final GeoPosition? position = await readDeviceLocationFix(location);
    if (!mounted) return;

    if (position == null) {
      setState(() {
        _detecting = false;
        _block = _LocationGateBlock.unavailable;
      });
      return;
    }

    if (!isWithinMacedonia(position.latitude, position.longitude)) {
      setState(() {
        _detecting = false;
        _block = _LocationGateBlock.outsideMacedonia;
      });
      return;
    }

    try {
      await ref
          .read(homeLocationControllerProvider.notifier)
          .saveHomeLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            label: _currentAddress,
          );
    } on AppError catch (error) {
      if (!mounted) return;
      setState(() {
        _detecting = false;
        _block = error.code == 'VALIDATION_ERROR'
            ? _LocationGateBlock.outsideMacedonia
            : _LocationGateBlock.unavailable;
      });
      return;
    }

    setState(() {
      _selectedPosition = LatLng(position.latitude, position.longitude);
      _detecting = false;
    });

    await _markGuidePending();
    if (!mounted) return;
    AppHaptics.success(context);
    await _navigateHomeWithCoachPending();
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    AppNavigation.goSignIn();
  }

  Future<void> _markGuidePending() async {
    try {
      await ref
          .read(featureGuideRepositoryProvider)
          .markPostRegistrationGuidePending();
    } on Object catch (e, st) {
      AppLog.warn(
        '[LocationScreen] markPostRegistrationGuidePending failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _navigateHomeWithCoachPending() async {
    if (!mounted) return;
    AppNavigation.navigateToHome(
      args: const HomeRouteArgs(startCoachTour: true),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkRouter.replayPendingAuthenticatedRoute(appGoRouter);
    });
  }

  String _blockedMessage(AppLocalizations l10n) {
    return switch (_block) {
      _LocationGateBlock.outsideMacedonia => l10n.authLocationGateOutsideBody,
      _LocationGateBlock.unavailable => l10n.authLocationGateUnavailableBody,
      _LocationGateBlock.none => '',
    };
  }

  bool get _isBlocked => _block != _LocationGateBlock.none;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final locationState = ref.watch(homeLocationControllerProvider);
    final bool isSaving = locationState.isLoading;
    final String? apiError = locationState.error != null
        ? messageForAuthError(l10n, locationState.error!)
        : null;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bool isBlocked = _isBlocked;

    return Stack(
      children: <Widget>[
        PopScope(
          canPop: false,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppColors.panelBackground,
            body: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: SafeArea(
                child: AnimatedPadding(
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: SingleChildScrollView(
                    physics: AuthFormScrollPhysics.resolve(context),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.radiusSm),
                        Text(
                          isBlocked &&
                                  _block == _LocationGateBlock.outsideMacedonia
                              ? l10n.authLocationGateOutsideTitle
                              : l10n.authLocationTitle,
                          style: AppTypography.authScreenTitle(textTheme),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isBlocked
                              ? _blockedMessage(l10n)
                              : l10n.authLocationSubtitle,
                          style: AppTypography.authScreenSubtitle(textTheme),
                        ),
                        if (apiError != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          ApiErrorBanner(
                            message: apiError,
                            onDismiss: () => ref
                                .read(homeLocationControllerProvider.notifier)
                                .clearError(),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildMap(l10n, textTheme),
                        const SizedBox(height: AppSpacing.radiusPill),
                        _buildPrimaryAction(l10n),
                        if (isBlocked && !_detecting) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: AppButton.text(
                              label: l10n.feedNoLocationOpenSettings,
                              onPressed: () => unawaited(
                                showLocationOpenSettingsDialog(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Center(
                            child: AppButton.text(
                              label: l10n.profileSignOutTile,
                              onPressed: () => unawaited(_signOut()),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.authLocationPrivacyNote,
                          style: AppTypography.cardSubtitle(
                            textTheme,
                          ).copyWith(height: 1.35),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        LoadingOverlay(visible: isSaving || _detecting),
      ],
    );
  }

  Widget _buildPrimaryAction(AppLocalizations l10n) {
    final String label = _detecting
        ? l10n.authLocationDetecting
        : _isBlocked
        ? l10n.authLocationTryAgain
        : l10n.authLocationUseCurrent;
    return Semantics(
      button: true,
      label: label,
      child: AppButton.primary(
        label: label,
        enabled: !_detecting,
        onPressed: _detecting ? null : () => unawaited(_confirmLocation()),
      ),
    );
  }

  Widget _buildMap(AppLocalizations l10n, TextTheme textTheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            FlutterMap(
              key: ValueKey<bool>(_selectedPosition != null),
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPosition ?? _mapCenter,
                initialZoom: _selectedPosition != null ? 15 : 7,
                minZoom: 1.5,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const <String>['a', 'b', 'c', 'd'],
                  maxNativeZoom: 20,
                  userAgentPackageName: 'chisto_mobile',
                  retinaMode: false,
                  tileProvider:
                      widget.tileProviderOverride ??
                      createCachedTileProvider(maxStaleDays: 30),
                  tileDisplay: const TileDisplay.instantaneous(),
                ),
                if (_selectedPosition != null)
                  MarkerLayer(
                    markers: <Marker>[
                      Marker(
                        point: _selectedPosition!,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(
                              alpha: 0.82,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (_showTileLoadingOverlay ||
                (_detecting && _selectedPosition == null))
              const Positioned.fill(
                child: IgnorePointer(child: _MapTileSkeleton()),
              ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.radiusSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  _currentAddress ?? l10n.authLocationMapPlaceholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.pillLabel(textTheme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTileSkeleton extends StatefulWidget {
  const _MapTileSkeleton();

  @override
  State<_MapTileSkeleton> createState() => _MapTileSkeletonState();
}

class _MapTileSkeletonState extends State<_MapTileSkeleton>
    with SingleTickerProviderStateMixin {
  static const int _columns = 4;
  static const double _gap = AppSpacing.xs;
  static const double _radius = 8;

  late final AnimationController _shimmerController;
  bool _didConfigureMotion = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didConfigureMotion) return;
    _didConfigureMotion = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmerController.value = 0;
    } else {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (BuildContext context, Widget? child) {
        final double t = _shimmerController.value;
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const <Color>[
                AppColors.inputFill,
                AppColors.panelBackground,
                AppColors.inputFill,
              ],
              stops: <double>[
                (t - 0.25).clamp(0.0, 1.0),
                t,
                (t + 0.25).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.panelBackground,
        padding: const EdgeInsets.all(AppSpacing.insetTight),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            const double totalGapW = _gap * (_columns - 1);
            final double tileW = (w - totalGapW - _gap) / _columns;
            final int rows = ((h + _gap) / (tileW + _gap)).floor().clamp(2, 6);
            final double totalGapH = _gap * (rows - 1);
            final double tileH = (h - totalGapH - _gap) / rows;
            return Column(
              children: List<Widget>.generate(rows, (int row) {
                return Padding(
                  padding: row < rows - 1
                      ? const EdgeInsets.only(bottom: AppSpacing.xs)
                      : EdgeInsets.zero,
                  child: Row(
                    children: List<Widget>.generate(_columns, (int col) {
                      return Padding(
                        padding: col < _columns - 1
                            ? const EdgeInsets.only(right: AppSpacing.xs)
                            : EdgeInsets.zero,
                        child: Container(
                          width: tileW,
                          height: tileH,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(_radius),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

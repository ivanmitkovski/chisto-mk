import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_feed_screen.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_map_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/new_report_screen.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:chisto_mobile/features/events/presentation/screens/events_feed_screen.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/reports_list_screen.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_review_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/services.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  String? _reportIdToOpen;
  int _reportsRefreshTrigger = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _feedKey = GlobalKey();
  final GlobalKey _eventsFeedKey = GlobalKey();
  bool _isLaunchingReportFlow = false;

  bool _hasVisitedMap = false;
  final ValueNotifier<String?> _mapPendingSiteFocus = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex.clamp(0, 3);
    _hasVisitedMap = _currentIndex == 2;
  }

  @override
  void dispose() {
    _mapPendingSiteFocus.dispose();
    super.dispose();
  }

  void _requestShowSiteOnMap(String siteId) {
    setState(() {
      _currentIndex = 2;
      _hasVisitedMap = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapPendingSiteFocus.value = siteId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          PollutionFeedScreen(key: _feedKey),
          ReportsListScreen(
            initialReportIdToOpen: _reportIdToOpen,
            onReportOpened: () => setState(() => _reportIdToOpen = null),
            refreshTrigger: _reportsRefreshTrigger,
            onShowSiteOnMap: _requestShowSiteOnMap,
          ),
          _hasVisitedMap
              ? PollutionMapScreen(
                  pendingSiteFocus: _mapPendingSiteFocus,
                )
              : _MapTabPlaceholder(),
          EventsFeedScreen(
            key: _eventsFeedKey,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.panelBackground,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: HomeBottomNavBar(
                    currentIndex: _currentIndex,
                    onTabSelected: _handleTabSelected,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: -30,
                  child: Center(
                    child: _CentralReportButton(
                      enabled: !_isLaunchingReportFlow,
                      onPressed: _handleCentralActionPressed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTabSelected(int index) {
    if (index == _currentIndex) {
      if (index == 0) {
        final dynamic state = _feedKey.currentState;
        if (state != null) state.scrollToTop();
      } else if (index == 3) {
        final dynamic state = _eventsFeedKey.currentState;
        if (state != null) state.scrollToTop();
      }
      return;
    }

    setState(() {
      _currentIndex = index;
      if (index == 2) _hasVisitedMap = true;
    });

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dynamic state = _feedKey.currentState;
        if (state != null) state.scrollToTop();
      });
    } else if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dynamic state = _eventsFeedKey.currentState;
        if (state != null) state.scrollToTop();
      });
    }
  }

  Future<void> _handleCentralActionPressed() async {
    if (_isLaunchingReportFlow) {
      return;
    }

    setState(() {
      _isLaunchingReportFlow = true;
    });

    try {
      final bool canProceed = await _ensureCanStartReportFlow();
      if (!canProceed) return;
      await _captureAndReview();
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingReportFlow = false;
        });
      }
    }
  }

  Future<bool> _ensureCanStartReportFlow() async {
    try {
      final capacity = await ServiceLocator.instance.reportsApiRepository.getReportingCapacity();
      if (capacity.creditsAvailable > 0 || capacity.emergencyAvailable) {
        return true;
      }
      if (!mounted) return false;
      return showReportingCooldownDialog(context, capacity);
    } on AppError catch (e) {
      if (!mounted) return false;
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'ACCOUNT_NOT_ACTIVE') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return false;
      }
      AppSnack.show(
        context,
        message: e.message,
        type: AppSnackType.warning,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      AppSnack.show(
        context,
        message: 'Could not check reporting availability right now.',
        type: AppSnackType.warning,
      );
      return false;
    }
  }

  Future<void> _captureAndReview() async {
    XFile? file;
    try {
      file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
        maxWidth: 2048,
      );
    } on PlatformException {
      if (mounted) {
        AppSnack.show(
          context,
          message:
              'Unable to open the camera right now. Please try again in a moment.',
          type: AppSnackType.warning,
        );
      }
      return;
    }

    if (!mounted || file == null) return;
    final XFile selectedFile = file;

    final PhotoReviewResult? result =
        await showModalBottomSheet<PhotoReviewResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.panelBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
          ),
          builder: (_) => PhotoReviewSheet(file: selectedFile),
        );

    if (!mounted) return;

    if (result == PhotoReviewResult.retake) {
      await _captureAndReview();
    } else if (result == PhotoReviewResult.use) {
      AppHaptics.softTransition();
      final Object? result = await Navigator.of(context).push<Object>(
        MaterialPageRoute<Object>(
          builder: (_) => NewReportScreen(
            initialPhoto: selectedFile,
            entryLabel: 'Camera report',
            entryHint:
                'Starting from a live photo can speed up moderation because the evidence is already attached.',
          ),
        ),
      );
      if (result != null && mounted) {
        setState(() {
          _currentIndex = 1;
          _reportsRefreshTrigger++;
          if (result is String) _reportIdToOpen = result;
        });
      }
    }
  }
}

class _CentralReportButton extends StatefulWidget {
  const _CentralReportButton({required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<_CentralReportButton> createState() => _CentralReportButtonState();
}

class _CentralReportButtonState extends State<_CentralReportButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTap: () {
        if (!widget.enabled) {
          return;
        }
        AppHaptics.medium();
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? 0.94 : 1.0,
        duration: AppMotion.xFast,
        curve: AppMotion.standardCurve,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: widget.enabled ? 1 : 0.72,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.enabled
                ? const Icon(CupertinoIcons.add, color: AppColors.textOnDark, size: 28)
                : const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight placeholder until the user opens the map tab (lazy loading).
class _MapTabPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.appBackground,
      child: Center(
        child: Icon(
          Icons.map_outlined,
          size: 48,
          color: AppColors.textMuted.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/screens/events_feed_screen.dart'
    show EventsFeedScreenState;
import 'package:chisto_mobile/features/home/presentation/navigation/home_shell_router.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/new_report_screen.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/reports_list_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_review_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.initialTabIndex = 0,
    this.mapSiteIdToFocus,
  });

  final int initialTabIndex;

  /// When set, opens the map tab and focuses this site (deep link / notification).
  final String? mapSiteIdToFocus;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String? _reportIdToOpen;
  int _reportsRefreshTrigger = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _feedKey = GlobalKey();
  final GlobalKey<EventsFeedScreenState> _eventsFeedKey =
      GlobalKey<EventsFeedScreenState>();
  bool _isLaunchingReportFlow = false;

  final ValueNotifier<String?> _mapPendingSiteFocus = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<bool> _isLaunchingReportNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<int> _reportsRefreshNotifier = ValueNotifier<int>(0);

  late final GoRouter _homeRouter;

  @override
  void initState() {
    super.initState();
    final int tab = widget.initialTabIndex.clamp(0, 3);
    final String? focusId = widget.mapSiteIdToFocus?.trim();
    final String initialLocation =
        focusId != null && focusId.isNotEmpty && tab == 2
            ? '/map'
            : homeShellTabIndexToLocation(tab);

    _homeRouter = buildHomeShellGoRouter(
      initialLocation: initialLocation,
      mapPendingSiteFocus: _mapPendingSiteFocus,
      feedKey: _feedKey,
      eventsFeedKey: _eventsFeedKey,
      reportsPageBuilder: (BuildContext context) {
        return ReportsListScreen(
          initialReportIdToOpen: _reportIdToOpen,
          onReportOpened: () => setState(() => _reportIdToOpen = null),
          refreshTrigger: _reportsRefreshTrigger,
          onShowSiteOnMap: _requestShowSiteOnMap,
        );
      },
      onCentralReportPressed: _handleCentralActionPressed,
      isLaunchingReportFlow: _isLaunchingReportNotifier,
      refreshListenable: Listenable.merge(<Listenable>[
        _reportsRefreshNotifier,
        _isLaunchingReportNotifier,
      ]),
    );

    if (focusId != null && focusId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapPendingSiteFocus.value = focusId;
        }
      });
    }
  }

  @override
  void dispose() {
    _homeRouter.dispose();
    _mapPendingSiteFocus.dispose();
    _isLaunchingReportNotifier.dispose();
    _reportsRefreshNotifier.dispose();
    super.dispose();
  }

  void _requestShowSiteOnMap(String siteId) {
    _mapPendingSiteFocus.value = siteId;
    _homeRouter.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    return Router.withConfig(
      restorationScopeId: 'homeShellRouter',
      config: _homeRouter,
    );
  }

  Future<void> _handleCentralActionPressed() async {
    if (_isLaunchingReportFlow) {
      return;
    }

    setState(() {
      _isLaunchingReportFlow = true;
    });
    _isLaunchingReportNotifier.value = true;

    try {
      final bool canProceed = await _ensureCanStartReportFlow();
      if (!canProceed) {
        return;
      }
      await _captureAndReview();
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingReportFlow = false;
        });
        _isLaunchingReportNotifier.value = false;
      }
    }
  }

  Future<bool> _ensureCanStartReportFlow() async {
    try {
      final capacity = await ServiceLocator.instance.reportsApiRepository
          .getReportingCapacity();
      if (capacity.creditsAvailable > 0 || capacity.emergencyAvailable) {
        return true;
      }
      if (!mounted) {
        return false;
      }
      return showReportingCooldownDialog(context, capacity);
    } on AppError catch (e) {
      if (!mounted) {
        return false;
      }
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'ACCOUNT_NOT_ACTIVE') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
        return false;
      }
      AppSnack.show(context, message: e.message, type: AppSnackType.warning);
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      AppSnack.show(
        context,
        message: context.l10n.homeReportingCapacityCheckFailed,
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
          message: context.l10n.homeCameraOpenFailed,
          type: AppSnackType.warning,
        );
      }
      return;
    }

    if (!mounted || file == null) {
      return;
    }
    final XFile selectedFile = file;

    final PhotoReviewResult? result =
        await showModalBottomSheet<PhotoReviewResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.panelBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          builder: (_) => PhotoReviewSheet(file: selectedFile),
        );

    if (!mounted) {
      return;
    }

    if (result == PhotoReviewResult.retake) {
      await _captureAndReview();
    } else if (result == PhotoReviewResult.use) {
      AppHaptics.softTransition();
      final Object? navResult = await Navigator.of(context).push<Object>(
        MaterialPageRoute<Object>(
          builder: (_) => NewReportScreen(initialPhoto: selectedFile),
        ),
      );
      if (navResult != null && mounted) {
        setState(() {
          _homeRouter.go('/reports');
          _reportsRefreshTrigger++;
          _reportsRefreshNotifier.value = _reportsRefreshTrigger;
          if (navResult is String) {
            _reportIdToOpen = navResult;
          }
        });
      }
    }
  }
}

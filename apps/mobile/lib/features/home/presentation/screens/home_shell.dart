import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_feed_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/new_report_screen.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/reports_list_screen.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/photo_review_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/services.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _feedKey = GlobalKey();
  bool _isLaunchingReportFlow = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          PollutionFeedScreen(key: _feedKey),
          const ReportsListScreen(),
          const _PlaceholderScreen(title: 'Map'),
          const _PlaceholderScreen(title: 'Events'),
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
        if (state != null) {
          state.scrollToTop();
        }
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dynamic state = _feedKey.currentState;
        if (state != null) {
          state.scrollToTop();
        }
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
      await _captureAndReview();
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingReportFlow = false;
        });
      }
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => PhotoReviewSheet(file: selectedFile),
        );

    if (!mounted) return;

    if (result == PhotoReviewResult.retake) {
      await _captureAndReview();
    } else if (result == PhotoReviewResult.use) {
      AppHaptics.softTransition();
      final bool? submitted = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => NewReportScreen(
            initialPhoto: selectedFile,
            entryLabel: 'Camera report',
            entryHint:
                'Starting from a live photo can speed up moderation because the evidence is already attached.',
          ),
        ),
      );
      if (submitted == true && mounted) {
        setState(() => _currentIndex = 1);
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
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.enabled
                ? const Icon(CupertinoIcons.add, color: Colors.white, size: 28)
                : const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

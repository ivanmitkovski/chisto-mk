import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_feed_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/take_action_bottom_sheet.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _feedKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          PollutionFeedScreen(key: _feedKey),
          const _PlaceholderScreen(title: 'Reports'),
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
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
      maxWidth: 2048,
    );

    if (!mounted || file == null) {
      return;
    }

    // TODO: Navigate into report creation flow with the captured file.
    AppSnack.show(
      context,
      message: 'Photo captured. Reporting flow coming next.',
      type: AppSnackType.success,
      duration: const Duration(milliseconds: 1400),
    );
  }
}

class _CentralReportButton extends StatefulWidget {
  const _CentralReportButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_CentralReportButton> createState() => _CentralReportButtonState();
}

class _CentralReportButtonState extends State<_CentralReportButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
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
          child: const Icon(
            CupertinoIcons.add,
            color: Colors.white,
            size: 28,
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
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}


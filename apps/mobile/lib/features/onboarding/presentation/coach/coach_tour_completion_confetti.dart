import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/onboarding/presentation/coach/coach_tour_visual_policy.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

/// Invisible full-screen layer: confetti + success haptics when the coach tour finishes.
/// No modal card—shell stays visible underneath until the controller hides the tour.
class CoachTourCompletionConfettiLayer extends StatefulWidget {
  const CoachTourCompletionConfettiLayer({super.key});

  @override
  State<CoachTourCompletionConfettiLayer> createState() =>
      _CoachTourCompletionConfettiLayerState();
}

class _CoachTourCompletionConfettiLayerState
    extends State<CoachTourCompletionConfettiLayer> {
  bool _confettiLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _launchConfettiIfAllowed();
      AppHaptics.success(context);
    });
  }

  void _launchConfettiIfAllowed() {
    if (_confettiLaunched) {
      return;
    }
    _confettiLaunched = true;
    if (!CoachTourVisualPolicy.useCompletionConfetti(context)) {
      return;
    }
    Confetti.launch(
      context,
      options: ConfettiOptions(
        particleCount: 36,
        spread: 50,
        angle: 90,
        startVelocity: 32,
        gravity: 0.42,
        decay: 0.93,
        y: 0.32,
        x: 0.5,
        colors: const <Color>[
          AppColors.primary,
          AppColors.primaryDark,
          AppColors.accentWarning,
          AppColors.white,
        ],
        scalar: 0.75,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AbsorbPointer(
      child: ColoredBox(color: Colors.transparent, child: SizedBox.expand()),
    );
  }
}

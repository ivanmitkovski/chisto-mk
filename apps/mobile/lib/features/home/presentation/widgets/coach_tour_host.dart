import 'dart:async';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/home_shell_coach_keys.dart';
import 'package:chisto_mobile/features/onboarding/application/coach_tour_controller.dart';
import 'package:chisto_mobile/features/onboarding/domain/coach_tour_step.dart';
import 'package:chisto_mobile/features/onboarding/presentation/coach/coach_tour_completion_confetti.dart';
import 'package:chisto_mobile/features/onboarding/presentation/coach/coach_tour_illustrations.dart';
import 'package:chisto_mobile/features/onboarding/presentation/coach/coach_tour_layout.dart';
import 'package:chisto_mobile/features/onboarding/presentation/coach/coach_tour_scrim.dart';
import 'package:chisto_mobile/features/onboarding/presentation/coach/coach_tour_visual_policy.dart';
import 'package:chisto_mobile/features/onboarding/presentation/widgets/story_guide_progress_bar.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';

export 'package:chisto_mobile/features/onboarding/presentation/coach/coach_tour_scrim.dart'
    show CoachTourScrimPainter;

bool _coachRectsNearlyEqual(Rect a, Rect b, {double eps = 3}) {
  return (a.left - b.left).abs() <= eps &&
      (a.top - b.top).abs() <= eps &&
      (a.width - b.width).abs() <= eps &&
      (a.height - b.height).abs() <= eps;
}

/// Modal spotlight layer: scrim + optional cutout + tooltip (design-system card).
class CoachTourHost extends StatefulWidget {
  const CoachTourHost({
    super.key,
    required this.controller,
    required this.keys,
    required this.navigationShell,
  });

  final CoachTourController controller;
  final HomeShellCoachKeys keys;
  final StatefulNavigationShell navigationShell;

  @override
  State<CoachTourHost> createState() => _CoachTourHostState();
}

class _CoachTourHostState extends State<CoachTourHost>
    with SingleTickerProviderStateMixin {
  Rect? _holeRectGlobal;
  int _layoutGeneration = 0;
  int _measureAttempts = 0;
  static const int _maxMeasureAttempts = 12;
  int _lastAnnouncedStep = -1;
  bool _holeMeasurementFailed = false;
  int _fadeSession = 0;
  bool _hadCoachVisibility = false;

  late final AnimationController _holeMorphController;
  late final CurvedAnimation _holeMorphCurved;
  Rect? _morphedHoleLocal;
  Rect? _holeTweenFrom;
  Rect? _holeTweenTo;
  bool _holeMorphPostFrameScheduled = false;
  Rect? _pendingHoleMorphTarget;
  bool _pendingHoleMorphReduceMotion = false;

  @override
  void initState() {
    super.initState();
    _holeMorphController = AnimationController(
      vsync: this,
      duration: AppMotion.coachHoleMorph,
    );
    _holeMorphCurved = CurvedAnimation(
      parent: _holeMorphController,
      curve: AppMotion.coachHoleMorphCurve,
    );
    _holeMorphCurved.addListener(_onHoleMorphTick);
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleLayout());
  }

  @override
  void dispose() {
    _holeMorphCurved.removeListener(_onHoleMorphTick);
    _holeMorphCurved.dispose();
    _holeMorphController.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onHoleMorphTick() {
    final Rect? from = _holeTweenFrom;
    final Rect? to = _holeTweenTo;
    if (!mounted || from == null || to == null) {
      return;
    }
    setState(() {
      _morphedHoleLocal = Rect.lerp(from, to, _holeMorphCurved.value);
    });
  }

  void _ensureHoleMorphScheduled(Rect? target, bool reduceMotion) {
    _pendingHoleMorphTarget = target;
    _pendingHoleMorphReduceMotion = reduceMotion;
    if (_holeMorphPostFrameScheduled) {
      return;
    }
    _holeMorphPostFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _holeMorphPostFrameScheduled = false;
      if (!mounted) {
        return;
      }
      _applyHoleMorphNow(
        _pendingHoleMorphTarget,
        _pendingHoleMorphReduceMotion,
      );
    });
  }

  void _applyHoleMorphNow(Rect? target, bool reduceMotion) {
    if (reduceMotion) {
      if (_morphedHoleLocal == target) {
        return;
      }
      setState(() {
        _morphedHoleLocal = target;
        _holeTweenFrom = target;
        _holeTweenTo = target;
      });
      _holeMorphController.stop();
      return;
    }
    if (target == null) {
      if (_morphedHoleLocal == null && !_holeMorphController.isAnimating) {
        return;
      }
      setState(() {
        _morphedHoleLocal = null;
        _holeTweenFrom = null;
        _holeTweenTo = null;
      });
      _holeMorphController.stop();
      return;
    }
    if (_morphedHoleLocal == null) {
      setState(() {
        _morphedHoleLocal = target;
        _holeTweenFrom = target;
        _holeTweenTo = target;
      });
      _holeMorphController.value = 1.0;
      return;
    }
    if (_morphedHoleLocal == target) {
      return;
    }
    if (!_holeMorphController.isAnimating &&
        _morphedHoleLocal != null &&
        _coachRectsNearlyEqual(_morphedHoleLocal!, target)) {
      return;
    }
    if (_holeTweenTo == target && _holeMorphController.isAnimating) {
      return;
    }
    _holeTweenFrom = _morphedHoleLocal;
    _holeTweenTo = target;
    _holeMorphController.forward(from: 0);
  }

  void _onControllerChanged() {
    if (!widget.controller.isVisible) {
      _hadCoachVisibility = false;
      _holeMorphController.stop();
      setState(() {
        _holeRectGlobal = null;
        _lastAnnouncedStep = -1;
        _holeMeasurementFailed = false;
        _morphedHoleLocal = null;
        _holeTweenFrom = null;
        _holeTweenTo = null;
      });
      return;
    }
    if (!_hadCoachVisibility) {
      _fadeSession++;
    }
    _hadCoachVisibility = true;
    if (widget.controller.isCelebratingCompletion) {
      return;
    }
    _scheduleLayout();
  }

  void _scheduleLayout() {
    if (!widget.controller.isVisible) {
      return;
    }
    final int gen = ++_layoutGeneration;
    _measureAttempts = 0;
    _holeMeasurementFailed = false;
    final CoachTourStep step = widget.controller.currentStep;
    widget.navigationShell.goBranch(step.requiredTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _layoutGeneration) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || gen != _layoutGeneration) {
          return;
        }
        _measureHole(gen);
      });
    });
  }

  void _measureHole(int gen) {
    if (!mounted || gen != _layoutGeneration || !widget.controller.isVisible) {
      return;
    }
    if (widget.controller.isCelebratingCompletion) {
      return;
    }
    final CoachTourTarget t = widget.controller.currentStep.target;
    Rect? r;
    switch (t) {
      case CoachTourTarget.none:
        r = null;
        break;
      case CoachTourTarget.navHome:
        r = _globalRect(widget.keys.navItemKeys[0]);
        break;
      case CoachTourTarget.navReports:
        r = _globalRect(widget.keys.navItemKeys[1]);
        break;
      case CoachTourTarget.navMap:
        r = _globalRect(widget.keys.navItemKeys[2]);
        break;
      case CoachTourTarget.navEvents:
        r = _globalRect(widget.keys.navItemKeys[3]);
        break;
      case CoachTourTarget.centralFab:
        r = _globalRect(widget.keys.fabKey);
        break;
      case CoachTourTarget.profileAvatar:
        r = _globalRect(widget.keys.profileAvatarKey);
        break;
    }
    if (r == null &&
        t != CoachTourTarget.none &&
        _measureAttempts < _maxMeasureAttempts) {
      _measureAttempts++;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureHole(gen));
      return;
    }
    final bool failed = r == null && t != CoachTourTarget.none;
    setState(() {
      _holeRectGlobal = r;
      _holeMeasurementFailed = failed;
    });
  }

  Rect? _globalRect(GlobalKey key) {
    final BuildContext? ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) {
      return null;
    }
    final RenderObject? ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) {
      return null;
    }
    final Offset topLeft = ro.localToGlobal(Offset.zero);
    return topLeft & ro.size;
  }

  (String title, String body) _copy(AppLocalizations l10n, int stepIndex) {
    return switch (stepIndex) {
      0 => (l10n.coachTourStep0Title, l10n.coachTourStep0Body),
      1 => (l10n.coachTourStep1Title, l10n.coachTourStep1Body),
      2 => (l10n.coachTourStep2Title, l10n.coachTourStep2Body),
      3 => (l10n.coachTourStep3Title, l10n.coachTourStep3Body),
      4 => (l10n.coachTourStep4Title, l10n.coachTourStep4Body),
      5 => (l10n.coachTourStep5Title, l10n.coachTourStep5Body),
      _ => (l10n.coachTourStep0Title, l10n.coachTourStep0Body),
    };
  }

  Future<void> _onCoachPrimaryPressed(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) async {
    AppHaptics.light(context);
    if (widget.controller.isLastStep) {
      try {
        await widget.controller.completeWithCelebration(
          reduceMotion: reduceMotion,
        );
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        AppSnack.show(
          context,
          message: l10n.coachTourCompleteFailed,
          type: AppSnackType.error,
        );
      }
    } else {
      widget.controller.next();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isVisible) {
      return const SizedBox.shrink();
    }

    if (widget.controller.isCelebratingCompletion) {
      return const Positioned.fill(child: CoachTourCompletionConfettiLayer());
    }

    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int step = widget.controller.stepIndex;
    final int total = widget.controller.stepCount;
    final (String title, String body) = _copy(l10n, step);

    if (step != _lastAnnouncedStep) {
      _lastAnnouncedStep = step;
      final String announcement =
          '${l10n.coachTourProgressSemantics(step + 1, total)}. $title';
      // ignore: deprecated_member_use
      SemanticsService.announce(
        announcement,
        Directionality.maybeOf(context) ?? TextDirection.ltr,
      );
    }

    final bool stepWantsHole =
        widget.controller.currentStep.target != CoachTourTarget.none;

    final RenderBox? hostBox = context.findRenderObject() as RenderBox?;
    Rect? localHole;
    if (hostBox != null && stepWantsHole && _holeRectGlobal != null) {
      final Offset o = hostBox.globalToLocal(_holeRectGlobal!.topLeft);
      localHole = o & _holeRectGlobal!.size;
    }
    final bool hasMeasuredHole =
        localHole != null &&
        !localHole.isEmpty &&
        stepWantsHole &&
        !_holeMeasurementFailed;

    final EdgeInsets pad = MediaQuery.paddingOf(context);
    final double viewInsetBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(_fadeSession),
        tween: Tween<double>(begin: 0, end: 1),
        duration: reduceMotion ? Duration.zero : AppMotion.coachScrimFade,
        curve: AppMotion.coachScrimCurve,
        builder: (BuildContext context, double fade, _) {
          return Opacity(
            opacity: fade,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double maxW = constraints.maxWidth;
                final double maxH = constraints.maxHeight;
                // No [BackdropFilter] here: a full-screen blur sits *under* the
                // scrim cutout, so the "hole" would show blurred pixels instead of
                // sharp shell content. Dimming is handled by [CoachTourScrimPainter].
                final bool vignetteGlow =
                    CoachTourVisualPolicy.useVignetteAndGlow(context);

                final Rect? holeMorphTarget = hasMeasuredHole
                    ? localHole
                    : null;
                _ensureHoleMorphScheduled(
                  stepWantsHole && !_holeMeasurementFailed
                      ? holeMorphTarget
                      : null,
                  reduceMotion,
                );
                final Rect? holePaintRect = reduceMotion
                    ? (stepWantsHole && !_holeMeasurementFailed
                          ? localHole
                          : null)
                    : (stepWantsHole && !_holeMeasurementFailed
                          ? (_morphedHoleLocal ?? localHole)
                          : null);

                final Widget scrimStack = Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: <Widget>[
                    Positioned.fill(
                      child: AbsorbPointer(
                        absorbing: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: CustomPaint(
                            painter: CoachTourScrimPainter(
                              holeRectLocal: holePaintRect,
                              scrimColor: AppColors.textPrimary.withValues(
                                alpha: 0.42,
                              ),
                              vignetteStrength: vignetteGlow ? 1.0 : 0.0,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    if (holePaintRect != null && vignetteGlow)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: CoachTourHoleRingPainter(
                              holeRectLocal: holePaintRect,
                              ringColor: AppColors.primary.withValues(
                                alpha: 0.55,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                );

                final CoachTourCardLayoutResult layout =
                    computeCoachTourCardLayout(
                      paddingInsets: pad,
                      maxWidth: maxW,
                      maxHeight: maxH,
                      estimatedCardHeight: 240,
                      margin: AppSpacing.lg,
                      verticalGap: AppSpacing.sm,
                      stepWantsHole: stepWantsHole,
                      holeMeasurementFailed: _holeMeasurementFailed,
                      localHole: localHole,
                      visualHole:
                          !reduceMotion &&
                              hasMeasuredHole &&
                              stepWantsHole &&
                              !_holeMeasurementFailed
                          ? holePaintRect
                          : null,
                      viewInsetBottom: viewInsetBottom,
                      textScaleFactor: MediaQuery.textScalerOf(
                        context,
                      ).scale(1),
                    );

                final String displayTitle =
                    _holeMeasurementFailed && stepWantsHole
                    ? l10n.coachTourTargetUnavailableTitle
                    : title;
                final String displayBody =
                    _holeMeasurementFailed && stepWantsHole
                    ? l10n.coachTourTargetUnavailableBody
                    : body;

                final IconData? illustration = coachTourIllustrationIcon(
                  widget.controller.currentStep.illustration,
                );

                final Widget tooltip = _CoachTooltipCard(
                  reduceMotion: reduceMotion,
                  illustration: illustration,
                  title: displayTitle,
                  body: displayBody,
                  layout: layout,
                  progressCurrent: step,
                  progressTotal: total,
                  primaryLabel: widget.controller.isLastStep
                      ? l10n.coachTourDone
                      : l10n.coachTourNext,
                  skipLabel: l10n.coachTourSkip,
                  skipSemantics: l10n.coachTourSkipSemantics,
                  busy: widget.controller.isBusy,
                  onNext: () {
                    unawaited(
                      _onCoachPrimaryPressed(context, l10n, reduceMotion),
                    );
                  },
                  onSkip: () {
                    AppHaptics.light(context);
                    unawaited(widget.controller.skip());
                  },
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[scrimStack, tooltip],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CoachTooltipCard extends StatelessWidget {
  const _CoachTooltipCard({
    required this.reduceMotion,
    required this.illustration,
    required this.title,
    required this.body,
    required this.layout,
    required this.progressCurrent,
    required this.progressTotal,
    required this.primaryLabel,
    required this.skipLabel,
    required this.skipSemantics,
    required this.busy,
    required this.onNext,
    required this.onSkip,
  });

  final bool reduceMotion;
  final IconData? illustration;
  final String title;
  final String body;
  final CoachTourCardLayoutResult layout;
  final int progressCurrent;
  final int progressTotal;
  final String primaryLabel;
  final String skipLabel;
  final String skipSemantics;
  final bool busy;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = AppTypography.textTheme;
    final Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Material(
        elevation: 8,
        shadowColor: AppColors.shadowLight.withValues(alpha: 0.5),
        color: AppColors.panelBackground,
        surfaceTintColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: AppColors.inputBorder.withValues(alpha: 0.9),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: KeyedSubtree(
            key: ValueKey<int>(progressCurrent),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ExcludeSemantics(
                      child: Text(
                        '${progressCurrent + 1}/$progressTotal',
                        style: tt.bodySmall!.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: skipSemantics,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          minimumSize: const Size(48, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        onPressed: busy ? null : onSkip,
                        child: Text(
                          skipLabel,
                          style: tt.titleSmall!.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (illustration != null) ...<Widget>[
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm + 2),
                        child: ExcludeSemantics(
                          child: Icon(
                            illustration,
                            size: 30,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: tt.titleMedium!.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium!.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                StoryGuideProgressBar(
                  count: progressTotal,
                  currentIndex: progressCurrent,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: primaryLabel,
                  onPressed: onNext,
                  enabled: !busy,
                  isLoading: busy,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final double sidePad = layout.sidePadding;
    switch (layout.placement) {
      case CoachTourCardVerticalPlacement.top:
        return Positioned(
          left: sidePad,
          right: sidePad,
          top: layout.top,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: layout.maxCardWidth),
              child: card,
            ),
          ),
        );
      case CoachTourCardVerticalPlacement.bottom:
        return Positioned(
          left: sidePad,
          right: sidePad,
          bottom: layout.bottom,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: layout.maxCardWidth),
              child: card,
            ),
          ),
        );
      case CoachTourCardVerticalPlacement.centerFill:
        return Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              sidePad,
              layout.top ?? AppSpacing.lg,
              sidePad,
              layout.bottom ?? AppSpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: layout.maxCardWidth),
                child: SingleChildScrollView(child: card),
              ),
            ),
          ),
        );
    }
  }
}

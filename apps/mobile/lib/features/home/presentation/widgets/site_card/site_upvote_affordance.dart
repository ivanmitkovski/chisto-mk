import 'dart:async';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_upvote_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

/// Feed icon vs detail stats chip — shared motion, press feedback, and busy state.
enum SiteUpvoteAffordanceVariant {
  barIcon,
  statChip,
}

/// Premium upvote control: press scale, short pop on tap, voted color, busy semantics.
///
/// Haptics remain in parents so auth, throttle, and outcome messaging stay in one place.
class SiteUpvoteAffordance extends StatefulWidget {
  const SiteUpvoteAffordance({
    super.key,
    required this.variant,
    required this.isUpvoted,
    required this.isBusy,
    required this.semanticsLabel,
    required this.onPressed,
    this.onLongPress,
    this.count,
    this.countTextStyle,
    this.semanticsLongPressHint,
  }) : assert(
          variant != SiteUpvoteAffordanceVariant.statChip || count != null,
          'statChip requires count',
        );

  final SiteUpvoteAffordanceVariant variant;
  final bool isUpvoted;
  final bool isBusy;
  final String semanticsLabel;
  final Future<void> Function()? onPressed;
  final VoidCallback? onLongPress;
  final int? count;
  final TextStyle? countTextStyle;
  final String? semanticsLongPressHint;

  @override
  State<SiteUpvoteAffordance> createState() => _SiteUpvoteAffordanceState();
}

class _SiteUpvoteAffordanceState extends State<SiteUpvoteAffordance>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: SiteUpvoteMotion.popDuration,
    )..addStatusListener((AnimationStatus s) {
        if (s == AnimationStatus.completed) {
          _pop.reset();
        }
      });
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.isBusy || widget.onPressed == null) {
      return;
    }
    setState(() => _pressed = false);
    if (SiteUpvoteMotion.microAnimationsEnabled(context)) {
      unawaited(_pop.forward(from: 0));
    }
    unawaited(widget.onPressed!());
  }

  void _pointerDown() {
    if (widget.isBusy) {
      return;
    }
    setState(() => _pressed = true);
  }

  void _pointerUpOrCancel() {
    if (!_pressed) {
      return;
    }
    setState(() => _pressed = false);
  }

  Widget _buildIcon(double size) {
    final Color iconColor = Color.lerp(
      AppColors.textPrimary,
      AppColors.primaryDark,
      widget.isUpvoted ? 1.0 : 0.0,
    )!;
    return Icon(
      widget.isUpvoted
          ? Icons.arrow_circle_up_rounded
          : Icons.arrow_circle_up_outlined,
      size: size,
      color: iconColor,
    );
  }

  Widget _scaledHitChild({required Widget child}) {
    final bool motion = SiteUpvoteMotion.microAnimationsEnabled(context);
    final double pressMul =
        _pressed && motion ? SiteUpvoteMotion.iconPressedScale : 1.0;
    return AnimatedBuilder(
      animation: _pop,
      builder: (BuildContext context, Widget? _) {
        final double popMul = motion
            ? 1.0 +
                (SiteUpvoteMotion.iconPopOvershoot - 1.0) *
                    Curves.easeOutBack.transform(_pop.value)
            : 1.0;
        final double scale = pressMul * popMul;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool motion = SiteUpvoteMotion.microAnimationsEnabled(context);

    switch (widget.variant) {
      case SiteUpvoteAffordanceVariant.barIcon:
        final Widget core = _scaledHitChild(child: _buildIcon(24));
        final Widget faded = AnimatedOpacity(
          duration: motion ? AppMotion.fast : Duration.zero,
          opacity: widget.isBusy ? 0.55 : 1,
          child: core,
        );
        return Semantics(
          button: true,
          enabled: !widget.isBusy,
          label: widget.semanticsLabel,
          child: Listener(
            onPointerDown: (_) => _pointerDown(),
            onPointerUp: (_) => _pointerUpOrCancel(),
            onPointerCancel: (_) => _pointerUpOrCancel(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.isBusy ? null : _handleTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: faded),
              ),
            ),
          ),
        );

      case SiteUpvoteAffordanceVariant.statChip:
        final Color chipLabelColor = Color.lerp(
          AppColors.textMuted,
          AppColors.primaryDark,
          widget.isUpvoted ? 1.0 : 0.0,
        )!;
        final TextStyle labelStyle =
            (widget.countTextStyle ?? AppTypography.chipLabel).copyWith(
          color: chipLabelColor,
        );
        final Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildIcon(16),
            const SizedBox(width: AppSpacing.xxs),
            Text('${widget.count}', style: labelStyle),
          ],
        );
        final Widget chip = AnimatedOpacity(
          duration: motion ? AppMotion.fast : Duration.zero,
          opacity: widget.isBusy ? 0.6 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: AppSpacing.xs,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _scaledHitChild(child: row),
          ),
        );
        return Semantics(
          button: true,
          enabled: !widget.isBusy,
          label: widget.semanticsLabel,
          hint: widget.semanticsLongPressHint,
          onLongPress: widget.onLongPress,
          child: Listener(
            onPointerDown: (_) => _pointerDown(),
            onPointerUp: (_) => _pointerUpOrCancel(),
            onPointerCancel: (_) => _pointerUpOrCancel(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.isBusy ? null : _handleTap,
              onLongPress: widget.onLongPress,
              child: chip,
            ),
          ),
        );
    }
  }
}

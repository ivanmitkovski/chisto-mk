import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Full-width discrete severity control (1–5) with iOS-style track and thumb.
class ReportSeveritySlider extends StatefulWidget {
  const ReportSeveritySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticsLabel,
    this.semanticsValue,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String? semanticsLabel;
  final String? semanticsValue;

  static const int min = 1;
  static const int max = 5;
  static const double thumbRadius = 14;

  @override
  State<ReportSeveritySlider> createState() => _ReportSeveritySliderState();
}

class _ReportSeveritySliderState extends State<ReportSeveritySlider> {
  int _lastHapticValue = 0;

  int _clamp(int v) =>
      v.clamp(ReportSeveritySlider.min, ReportSeveritySlider.max);

  double _valueToFraction(int v, double width) {
    final double travel = width - 2 * ReportSeveritySlider.thumbRadius;
    if (travel <= 0) {
      return 0;
    }
    return (v - ReportSeveritySlider.min) /
        (ReportSeveritySlider.max - ReportSeveritySlider.min);
  }

  int _fractionToValue(double fraction) {
    final double stepped =
        ReportSeveritySlider.min +
        fraction * (ReportSeveritySlider.max - ReportSeveritySlider.min);
    return stepped.round().clamp(
      ReportSeveritySlider.min,
      ReportSeveritySlider.max,
    );
  }

  void _emit(int next) {
    final int clamped = _clamp(next);
    if (clamped == widget.value) {
      return;
    }
    if (_lastHapticValue != clamped) {
      _lastHapticValue = clamped;
      AppHaptics.tap(context);
    }
    widget.onChanged(clamped);
  }

  void _updateFromLocalX(double localX, double width) {
    final double travel = width - 2 * ReportSeveritySlider.thumbRadius;
    if (travel <= 0) {
      return;
    }
    final double clampedX = localX.clamp(
      ReportSeveritySlider.thumbRadius,
      width - ReportSeveritySlider.thumbRadius,
    );
    final double fraction =
        (clampedX - ReportSeveritySlider.thumbRadius) / travel;
    _emit(_fractionToValue(fraction));
  }

  @override
  void initState() {
    super.initState();
    _lastHapticValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant ReportSeveritySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _lastHapticValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int value = _clamp(widget.value);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double fraction = _valueToFraction(value, width);
        final double travel = width - 2 * ReportSeveritySlider.thumbRadius;
        final double thumbCenterX =
            ReportSeveritySlider.thumbRadius + fraction * travel;
        final double activeWidth = thumbCenterX;

        return Semantics(
          slider: true,
          label: widget.semanticsLabel,
          value: widget.semanticsValue,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails d) =>
                _updateFromLocalX(d.localPosition.dx, width),
            onHorizontalDragUpdate: (DragUpdateDetails d) =>
                _updateFromLocalX(d.localPosition.dx, width),
            child: SizedBox(
              height: 44,
              width: width,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    height: 4,
                    width: width,
                    decoration: BoxDecoration(
                      color: AppColors.inputBorder.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 4,
                    width: activeWidth.clamp(0, width),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    left: thumbCenterX - ReportSeveritySlider.thumbRadius,
                    child: Container(
                      width: ReportSeveritySlider.thumbRadius * 2,
                      height: ReportSeveritySlider.thumbRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Low / Critical labels aligned to the slider thumb travel endpoints.
class ReportSeveritySliderLabels extends StatelessWidget {
  const ReportSeveritySliderLabels({
    super.key,
    required this.lowLabel,
    required this.criticalLabel,
  });

  final String lowLabel;
  final String criticalLabel;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ReportSeveritySlider.thumbRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(lowLabel, style: style),
          Text(criticalLabel, style: style),
        ],
      ),
    );
  }
}

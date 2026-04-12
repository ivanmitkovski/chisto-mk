import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/voice_recording_constants.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

/// iMessage-style scrolling level strip driven by [AudioRecorder.onAmplitudeChanged].
///
/// A [Ticker] smooths levels every frame and advances the scroll on a fixed time step,
/// so motion stays fluid instead of jumping once per native amplitude callback.
///
/// When [reduceMotion] is true, live updates are disabled and a static baseline is shown.
class VoiceRecordingMeter extends StatefulWidget {
  const VoiceRecordingMeter({
    super.key,
    required this.recorder,
    required this.active,
    required this.cancelled,
    required this.reduceMotion,
    this.barCount = 36,
  });

  final AudioRecorder recorder;
  final bool active;
  final bool cancelled;
  final bool reduceMotion;
  final int barCount;

  static const double maxBarHeight = VoiceRecordingConstants.maxBarHeight;
  static const double minBarHeight = VoiceRecordingConstants.minBarHeight;
  static const double barSpacing = VoiceRecordingConstants.barSpacing;

  @override
  State<VoiceRecordingMeter> createState() => _VoiceRecordingMeterState();
}

class _VoiceRecordingMeterState extends State<VoiceRecordingMeter>
    with SingleTickerProviderStateMixin {
  static const Duration _amplitudeInterval = VoiceRecordingConstants.amplitudeSampleInterval;
  static const double _scrollPeriodSec = VoiceRecordingConstants.scrollPeriodSeconds;
  static const double _dbMin = VoiceRecordingConstants.dbMin;
  static const double _dbMax = VoiceRecordingConstants.dbMax;
  static const double _followUpRate = VoiceRecordingConstants.followUpRate;
  static const double _followDownRate = VoiceRecordingConstants.followDownRate;

  StreamSubscription<Amplitude>? _amplitudeSub;
  Ticker? _ticker;
  late List<double> _levels;

  /// Raw target from mic (updated on stream only, no setState).
  double _targetNorm = 0;
  /// Low-passed level painted on the trailing edge every frame.
  double _smoothNorm = 0;
  double _scrollDebtSec = 0;
  Duration _lastTickElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _levels = List<double>.filled(widget.barCount, 0);
    if (widget.active && !widget.reduceMotion) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active && !widget.reduceMotion) {
          _startListening();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant VoiceRecordingMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.barCount != widget.barCount) {
      _levels = List<double>.filled(widget.barCount, 0);
    }
    final bool shouldRun = widget.active && !widget.reduceMotion;
    final bool wasRunning = oldWidget.active && !oldWidget.reduceMotion;
    if (shouldRun && !wasRunning) {
      _levels = List<double>.filled(widget.barCount, 0);
      _targetNorm = 0;
      _smoothNorm = 0;
      _scrollDebtSec = 0;
      _lastTickElapsed = Duration.zero;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active && !widget.reduceMotion) {
          _startListening();
        }
      });
    } else if (!shouldRun && wasRunning) {
      _stopListening();
      if (!widget.active) {
        _levels = List<double>.filled(widget.barCount, 0);
        _targetNorm = 0;
        _smoothNorm = 0;
      }
      setState(() {});
    } else if (widget.reduceMotion != oldWidget.reduceMotion) {
      _stopListening();
      if (widget.active && !widget.reduceMotion) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.active && !widget.reduceMotion) {
            _startListening();
          }
        });
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !widget.active || widget.reduceMotion) {
      return;
    }
    if (_lastTickElapsed == Duration.zero) {
      _lastTickElapsed = elapsed;
      return;
    }
    double dt = (elapsed - _lastTickElapsed).inMicroseconds / 1e6;
    _lastTickElapsed = elapsed;
    if (dt <= 0) {
      return;
    }
    if (dt > 0.18) {
      dt = 0.018;
    }

    final double err = _targetNorm - _smoothNorm;
    final double rate = err > 0 ? _followUpRate : _followDownRate;
    _smoothNorm += err * (1 - math.exp(-rate * dt));
    _smoothNorm = _smoothNorm.clamp(0.0, 1.0);

    _scrollDebtSec += dt;
    while (_scrollDebtSec >= _scrollPeriodSec) {
      _scrollDebtSec -= _scrollPeriodSec;
      for (int i = 0; i < _levels.length - 1; i++) {
        _levels[i] = _levels[i + 1];
      }
    }
    _levels[_levels.length - 1] = _smoothNorm;

    setState(() {});
  }

  void _startListening() {
    _stopListening();
    _levels = List<double>.filled(widget.barCount, 0);
    _targetNorm = 0;
    _smoothNorm = 0;
    _scrollDebtSec = 0;
    _lastTickElapsed = Duration.zero;

    _ticker = createTicker(_onTick)..start();

    _amplitudeSub = widget.recorder.onAmplitudeChanged(_amplitudeInterval).listen(
      (Amplitude amp) {
        if (!mounted || !widget.active || widget.reduceMotion) {
          return;
        }
        _targetNorm = _normalizeDbfs(amp.current);
      },
      onError: (_) {},
    );
  }

  void _stopListening() {
    _ticker?.dispose();
    _ticker = null;
    unawaited(_amplitudeSub?.cancel());
    _amplitudeSub = null;
  }

  /// Maps dBFS to [0,1]. Exponent above 1 reins in sustained loud input.
  static double _normalizeDbfs(double db) {
    if (db.isNaN || db.isInfinite) {
      return 0;
    }
    final double x = ((db.clamp(_dbMin, _dbMax) - _dbMin) / (_dbMax - _dbMin)).clamp(0.0, 1.0);
    return math.pow(x, 1.12).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final List<double> displayLevels;
    if (widget.reduceMotion && widget.active) {
      displayLevels = List<double>.filled(widget.barCount, 0.12);
    } else {
      displayLevels = _levels;
    }

    final Color barColor = widget.cancelled ? AppColors.accentDanger : AppColors.primary;

    return Semantics(
      label: context.l10n.eventChatVoiceLevelSemantic,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: CustomPaint(
          willChange: true,
          painter: _VoiceMeterPainter(
            levels: displayLevels,
            color: barColor,
            maxBarHeight: VoiceRecordingMeter.maxBarHeight,
            minBarHeight: VoiceRecordingMeter.minBarHeight,
            spacing: VoiceRecordingMeter.barSpacing,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _VoiceMeterPainter extends CustomPainter {
  _VoiceMeterPainter({
    required this.levels,
    required this.color,
    required this.maxBarHeight,
    required this.minBarHeight,
    required this.spacing,
  });

  final List<double> levels;
  final Color color;
  final double maxBarHeight;
  final double minBarHeight;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }
    final int n = levels.length;
    final double totalSpacing = spacing * (n - 1).clamp(0, n);
    final double barWidth = (size.width - totalSpacing) / n;
    if (barWidth <= 0) {
      return;
    }
    final double baseline = size.height;
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    double x = 0;
    for (int i = 0; i < n; i++) {
      final double t = levels[i].clamp(0.0, 1.0);
      final double h = minBarHeight + t * (maxBarHeight - minBarHeight);
      final double top = baseline - h;
      final RRect r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, h),
        Radius.circular(barWidth * 0.45),
      );
      canvas.drawRRect(r, paint);
      x += barWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceMeterPainter oldDelegate) {
    // [Ticker] updates every frame; always repaint (bounded by [RepaintBoundary]).
    return true;
  }
}

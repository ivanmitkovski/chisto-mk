import 'dart:async';

import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:flutter/foundation.dart';

/// Debounces transient realtime outages so brief ECS rollover blips do not flash UI banners.
class RealtimeDisruptionSignal {
  RealtimeDisruptionSignal({
    this.gracePeriod = const Duration(seconds: 4),
    required this.channel,
    this.resolveHost,
    this.resolveTransports,
    ValueNotifier<bool>? visible,
  }) : visible = visible ?? ValueNotifier<bool>(false);

  final Duration gracePeriod;
  final String channel;
  final String Function()? resolveHost;
  final String Function()? resolveTransports;
  final ValueNotifier<bool> visible;

  Timer? _graceTimer;
  DateTime? _outageStartedAt;
  bool _live = true;

  void setLive({required bool isLive}) {
    if (isLive) {
      _onLive();
    } else {
      _onNonLive();
    }
  }

  void _onLive() {
    _live = true;
    _graceTimer?.cancel();
    _graceTimer = null;

    final DateTime? started = _outageStartedAt;
    _outageStartedAt = null;

    if (visible.value) {
      visible.value = false;
      if (started != null) {
        _logRecovery(DateTime.now().difference(started));
      }
      return;
    }

    if (started != null) {
      AppLog.verbose(
        '[realtime:$channel] recovered within grace host=${resolveHost?.call() ?? "?"} '
        'outage=${DateTime.now().difference(started).inMilliseconds}ms',
      );
    }
  }

  void _onNonLive() {
    if (!_live && (_graceTimer?.isActive ?? false)) {
      return;
    }
    _live = false;
    _outageStartedAt ??= DateTime.now();
    if (visible.value) {
      return;
    }
    _graceTimer?.cancel();
    _graceTimer = Timer(gracePeriod, () {
      if (_live) {
        return;
      }
      visible.value = true;
      _logSustainedOutage();
    });
  }

  void _logSustainedOutage() {
    AppLog.warn(
      '[realtime:$channel] sustained outage host=${resolveHost?.call() ?? "?"} '
      'transports=${resolveTransports?.call() ?? "?"} grace=${gracePeriod.inSeconds}s',
      category: 'realtime',
    );
  }

  void _logRecovery(Duration outageDuration) {
    AppLog.warn(
      '[realtime:$channel] recovered host=${resolveHost?.call() ?? "?"} '
      'outage=${outageDuration.inMilliseconds}ms',
      category: 'realtime',
    );
  }

  void dispose() {
    _graceTimer?.cancel();
    _graceTimer = null;
    visible.dispose();
  }
}

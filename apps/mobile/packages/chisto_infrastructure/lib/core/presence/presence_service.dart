import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/presence/presence_screen_labels.dart';
import 'package:chisto_networking/src/network/api_client.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

/// REST presence heartbeat (~45s foreground) + offline beacon.
class PresenceService {
  PresenceService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  static const Duration heartbeatInterval = Duration(seconds: 45);
  static const Duration maxBackoff = Duration(minutes: 5);

  Timer? _timer;
  bool _foreground = true;
  bool _running = false;
  bool _appOpenedSent = false;
  String _currentScreen = 'Unknown';
  PackageInfo? _packageInfo;
  String? _deviceModel;
  String? _osVersion;
  Duration _backoff = Duration.zero;
  final Random _random = Random();

  String get currentScreen => _currentScreen;

  void setScreen(String screen) {
    final String trimmed = screen.trim();
    if (trimmed.isEmpty) return;
    _currentScreen = trimmed;
  }

  void setScreenFromPath(String path) {
    setScreen(presenceScreenLabelForPath(path));
  }

  void setForeground(bool value) {
    _foreground = value;
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _backoff = Duration.zero;
    await _ensureDeviceContext();
    if (!_appOpenedSent) {
      _appOpenedSent = true;
      unawaited(_post('/presence/app-opened', null));
    }
    unawaited(_sendHeartbeat());
    _timer?.cancel();
    _timer = Timer.periodic(heartbeatInterval, (_) {
      if (_foreground) {
        unawaited(_sendHeartbeat());
      }
    });
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    unawaited(_sendOffline());
  }

  Future<void> onResumed() async {
    _foreground = true;
    if (_running) {
      await _sendHeartbeat();
    }
  }

  Future<void> onPaused() async {
    _foreground = false;
    if (_running) {
      await _sendOffline();
    }
  }

  Future<void> _ensureDeviceContext() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    if (_deviceModel != null) return;
    try {
      final DeviceInfoPlugin plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        _deviceModel = 'web';
        _osVersion = 'web';
        return;
      }
      if (Platform.isIOS) {
        final IosDeviceInfo info = await plugin.iosInfo;
        _deviceModel = info.utsname.machine;
        _osVersion = info.systemVersion;
      } else if (Platform.isAndroid) {
        final AndroidDeviceInfo info = await plugin.androidInfo;
        _deviceModel = info.model;
        _osVersion = info.version.release;
      }
    } on Object catch (e, st) {
      AppLog.warn('presence device info failed', error: e, stackTrace: st);
    }
  }

  String get _platform {
    if (kIsWeb) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'ANDROID';
  }

  Map<String, dynamic> _heartbeatBody() => <String, dynamic>{
    'screen': _currentScreen,
    'appState': _foreground ? 'foreground' : 'background',
    'platform': _platform,
    'appVersion': _packageInfo?.version,
    'deviceModel': _deviceModel,
    'osVersion': _osVersion,
  };

  Future<void> _sendHeartbeat() async {
    await _post('/presence/heartbeat', _heartbeatBody());
  }

  Future<void> _sendOffline() async {
    await _post('/presence/offline', const <String, dynamic>{});
  }

  Future<void> _post(String path, Map<String, dynamic>? body) async {
    try {
      await _apiClient.post(
        path,
        body: body == null ? null : jsonEncode(body),
        headers: const <String, String>{'Content-Type': 'application/json'},
      );
      _backoff = Duration.zero;
    } on Object catch (e, st) {
      AppLog.warn('presence $path failed: $e', error: e, stackTrace: st);
      _scheduleBackoff();
    }
  }

  void _scheduleBackoff() {
    if (_backoff >= maxBackoff) return;
    final int baseMs = _backoff.inMilliseconds == 0 ? 1000 : _backoff.inMilliseconds * 2;
    final int jitter = _random.nextInt(500);
    _backoff = Duration(milliseconds: min(baseMs + jitter, maxBackoff.inMilliseconds));
  }
}

PresenceService? _globalPresenceService;

PresenceService? get globalPresenceService => _globalPresenceService;

void bindPresenceService(PresenceService service) {
  _globalPresenceService = service;
}

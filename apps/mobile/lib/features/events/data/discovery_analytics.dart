import 'dart:io';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-party funnel steps (no GPS, no free-text). Server accepts only when
/// deploy env enables ingest; mobile additionally requires opt-in consent.
enum DiscoveryFunnelStep {
  detailView('detail_view'),
  joinSuccess('join_success'),
  checkInSuccess('check_in_success');

  const DiscoveryFunnelStep(this.wireValue);

  final String wireValue;
}

/// Opt-in discovery funnel telemetry (upgrade #3). Off unless compile-time flag
/// **and** user consent in SharedPreferences.
class DiscoveryAnalytics {
  DiscoveryAnalytics._();

  static final DiscoveryAnalytics instance = DiscoveryAnalytics._();

  static const bool _kCompileInEnabled = bool.fromEnvironment(
    'DISCOVERY_ANALYTICS_ENABLED',
    defaultValue: false,
  );

  static const String _kIngestKey = String.fromEnvironment(
    'DISCOVERY_ANALYTICS_INGEST_KEY',
    defaultValue: '',
  );

  static const String _consentKey = 'discovery_analytics_consent_v1';

  /// Product/legal may enable capture for this install (SharedPreferences).
  static Future<void> setUserConsent(bool allowed) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, allowed);
  }

  static Future<bool> readUserConsent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  /// Fire-and-forget; never throws to callers.
  Future<void> maybeTrack(
    DiscoveryFunnelStep step, {
    required String eventId,
  }) async {
    if (!_kCompileInEnabled) {
      return;
    }
    try {
      if (!ServiceLocator.instance.isInitialized) {
        return;
      }
      if (!await readUserConsent()) {
        return;
      }
      if (!ServiceLocator.instance.authState.isAuthenticated) {
        return;
      }
      final PackageInfo info = await PackageInfo.fromPlatform();
      final String platform = Platform.isIOS ? 'ios' : 'android';
      final String trimmedKey = _kIngestKey.trim();
      await ServiceLocator.instance.apiClient.post(
        '/discovery-analytics/events',
        headers: trimmedKey.isNotEmpty
            ? <String, String>{'X-Chisto-Analytics-Key': trimmedKey}
            : null,
        body: <String, dynamic>{
          'eventId': eventId,
          'step': step.wireValue,
          'platform': platform,
          'appVersion': info.version,
        },
      );
    } on Object catch (_) {
      logEventsDiagnostic('discovery_analytics_post_failed');
    }
  }
}

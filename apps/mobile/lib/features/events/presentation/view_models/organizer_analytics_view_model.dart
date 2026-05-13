import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/features/events/domain/models/event_analytics.dart';

/// Loads organizer-only analytics for [OrganizerAnalyticsSection].
class OrganizerAnalyticsViewModel extends ChangeNotifier {
  OrganizerAnalyticsViewModel({
    required this.eventId,
    required this.fetchAnalytics,
  });

  final String eventId;
  final Future<EventAnalytics> Function(String eventId) fetchAnalytics;

  EventAnalytics? analytics;
  bool loading = true;
  bool silentRefresh = false;
  bool failed = false;

  bool _disposed = false;

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> fetch({required bool silent}) async {
    if (!silent) {
      loading = true;
      failed = false;
      _notifyIfAlive();
    } else {
      silentRefresh = true;
      _notifyIfAlive();
    }
    try {
      final EventAnalytics data = await fetchAnalytics(eventId);
      if (_disposed) return;
      analytics = data;
      loading = false;
      silentRefresh = false;
      failed = false;
      _notifyIfAlive();
    } on Object {
      if (_disposed) return;
      loading = false;
      silentRefresh = false;
      if (!silent) {
        failed = true;
        analytics = null;
      }
      _notifyIfAlive();
    }
  }
}

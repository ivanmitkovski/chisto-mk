import 'package:shared_preferences/shared_preferences.dart';

/// One-shot coaching for the report flow (e.g. help hint), persisted across sessions.
class ReportFlowPreferences {
  const ReportFlowPreferences();

  static const String _seenHelpHintKey = 'report_flow_seen_help_hint_v1';

  Future<bool> get hasSeenReportHelpHint async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenHelpHintKey) ?? false;
  }

  Future<void> setSeenReportHelpHint() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenHelpHintKey, true);
  }
}

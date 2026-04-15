import 'package:chisto_mobile/features/events/presentation/widgets/chat/voice_recording_meter.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

void main() {
  testWidgets('VoiceRecordingMeter paints when inactive (no polling timer)',
      (WidgetTester tester) async {
    // Real [AudioRecorder] is idle while [active] is false; dispose is omitted here
    // because platform dispose can block the test runner in some environments.
    final AudioRecorder recorder = AudioRecorder();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: VoiceRecordingMeter.maxBarHeight + 2,
            child: VoiceRecordingMeter(
              recorder: recorder,
              active: false,
              cancelled: false,
              reduceMotion: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(VoiceRecordingMeter), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(VoiceRecordingMeter),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('VoiceRecordingMeter reduceMotion shows static strip while active',
      (WidgetTester tester) async {
    final AudioRecorder recorder = AudioRecorder();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: VoiceRecordingMeter.maxBarHeight + 2,
            child: VoiceRecordingMeter(
              recorder: recorder,
              active: true,
              cancelled: false,
              reduceMotion: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VoiceRecordingMeter), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(VoiceRecordingMeter),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}

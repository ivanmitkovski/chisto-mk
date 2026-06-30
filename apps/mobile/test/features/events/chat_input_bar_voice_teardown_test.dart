import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_input_bar.dart';
import 'package:feature_events/src/presentation/widgets/chat/chat_voice_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

class _SpyChatVoiceRecorder implements ChatVoiceRecorder {
  bool _recording = true;
  final List<String> lifecycleCalls = <String>[];

  @override
  Future<void> cancel() async {
    lifecycleCalls.add('cancel');
    _recording = false;
  }

  @override
  Future<void> dispose() async {
    lifecycleCalls.add('dispose');
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> isRecording() async => _recording;

  @override
  Future<void> start({
    required RecordConfig config,
    required String path,
  }) async {}

  @override
  Future<String?> stop() async => null;
}

Widget _wrap(ChatInputBar bar) {
  return MaterialApp(
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: bar),
  );
}

void main() {
  testWidgets('dispose cancels active recording before recorder dispose', (
    WidgetTester tester,
  ) async {
    final _SpyChatVoiceRecorder spy = _SpyChatVoiceRecorder();

    await tester.pumpWidget(
      _wrap(
        ChatInputBar(
          onSend: (_) async {},
          onSendVoice: (_, __) async {},
          voiceRecorder: spy,
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      if (spy.lifecycleCalls.contains('dispose')) {
        break;
      }
    }

    expect(spy.lifecycleCalls, contains('cancel'));
    expect(spy.lifecycleCalls, contains('dispose'));
    expect(
      spy.lifecycleCalls.indexOf('cancel'),
      lessThan(spy.lifecycleCalls.indexOf('dispose')),
    );
  });
}

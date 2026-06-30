import 'package:record/record.dart';

/// Indirection over [AudioRecorder] for lifecycle tests and ordered teardown.
abstract class ChatVoiceRecorder {
  Future<bool> hasPermission();
  Future<void> start({required RecordConfig config, required String path});
  Future<void> cancel();
  Future<String?> stop();
  Future<bool> isRecording();
  Future<void> dispose();
}

class PackageChatVoiceRecorder implements ChatVoiceRecorder {
  PackageChatVoiceRecorder() : _inner = AudioRecorder();

  final AudioRecorder _inner;
  bool _disposed = false;

  /// Native recorder for amplitude UI ([VoiceRecordingMeter]).
  AudioRecorder get recorder => _inner;

  bool get isDisposed => _disposed;

  @override
  Future<bool> hasPermission() async {
    if (_disposed) return false;
    return _inner.hasPermission();
  }

  @override
  Future<void> start({
    required RecordConfig config,
    required String path,
  }) async {
    if (_disposed) return;
    return _inner.start(config, path: path);
  }

  @override
  Future<void> cancel() async {
    if (_disposed) return;
    return _inner.cancel();
  }

  @override
  Future<String?> stop() async {
    if (_disposed) return null;
    return _inner.stop();
  }

  @override
  Future<bool> isRecording() async {
    if (_disposed) return false;
    return _inner.isRecording();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _inner.dispose();
    } on Object {
      // Swallow native dispose errors (hot restart can race the recorder).
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;

/// Single [ja.AudioPlayer] for event chat so only one voice note plays at a time.
class EventChatAudioPlaybackController extends ChangeNotifier {
  EventChatAudioPlaybackController() {
    _playingSub = _player.playingStream.listen((_) => _emitIfAlive(notifyListeners));
    _durationSub = _player.durationStream.listen((_) => _emitIfAlive(notifyListeners));
    _processingSub = _player.processingStateStream.listen(_onProcessingState);
  }

  final ja.AudioPlayer _player = ja.AudioPlayer();
  String? _activeClipKey;
  bool _disposed = false;

  void _emitIfAlive(void Function() fn) {
    if (!_disposed) {
      fn();
    }
  }

  late final StreamSubscription<bool> _playingSub;
  late final StreamSubscription<Duration?> _durationSub;
  late final StreamSubscription<ja.ProcessingState> _processingSub;

  ja.AudioPlayer get player => _player;

  String? get activeClipKey => _activeClipKey;

  bool isActive(String clipKey) => _activeClipKey == clipKey;

  bool isActiveAndPlaying(String clipKey) =>
      _activeClipKey == clipKey && _player.playing;

  static bool _isRemoteUrl(String pathOrUrl) {
    final String s = pathOrUrl.trim();
    return s.startsWith('https://') || s.startsWith('http://');
  }

  void _onProcessingState(ja.ProcessingState state) {
    if (state == ja.ProcessingState.completed && _activeClipKey != null) {
      unawaited(_afterPlaybackCompleted());
    }
  }

  Future<void> _afterPlaybackCompleted() async {
    try {
      await _player.seek(Duration.zero);
      await _player.pause();
    } on Object {
      // ignore
    }
    _emitIfAlive(notifyListeners);
  }

  /// Stops the shared player and clears the active clip (e.g. before message actions).
  Future<void> stopActiveClip() async {
    if (_activeClipKey == null) {
      return;
    }
    try {
      await _player.stop();
    } on Object {
      // ignore
    }
    _activeClipKey = null;
    _emitIfAlive(notifyListeners);
  }

  Future<void> _seekToStartIfAtEnd() async {
    if (_player.processingState == ja.ProcessingState.completed) {
      await _player.seek(Duration.zero);
      return;
    }
    final Duration? d = _player.duration;
    if (d != null && d > Duration.zero) {
      final Duration pos = _player.position;
      if (pos >= d - const Duration(milliseconds: 90)) {
        await _player.seek(Duration.zero);
      }
    }
  }

  /// Play/pause [clipKey]. Switching clips stops the previous source.
  Future<void> toggle(String clipKey, String pathOrUrl) async {
    final String raw = pathOrUrl.trim();
    if (_activeClipKey == clipKey) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _seekToStartIfAtEnd();
        await _player.play();
      }
      if (_disposed) return;
      _emitIfAlive(notifyListeners);
      return;
    }
    try {
      await _player.stop();
    } on Object {
      // ignore
    }
    _activeClipKey = clipKey;
    try {
      if (_isRemoteUrl(raw)) {
        await _player.setUrl(raw);
      } else {
        final String path =
            raw.startsWith('file://') ? Uri.parse(raw).toFilePath() : raw;
        await _player.setFilePath(path);
      }
      await _player.play();
    } on Object {
      _activeClipKey = null;
      if (_disposed) return;
      _emitIfAlive(notifyListeners);
      return;
    }
    if (_disposed) return;
    _emitIfAlive(notifyListeners);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_playingSub.cancel());
    unawaited(_durationSub.cancel());
    unawaited(_processingSub.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}

class EventChatAudioPlaybackScope extends InheritedNotifier<EventChatAudioPlaybackController> {
  const EventChatAudioPlaybackScope({
    super.key,
    required EventChatAudioPlaybackController controller,
    required super.child,
  }) : super(notifier: controller);

  static EventChatAudioPlaybackController of(BuildContext context) {
    final EventChatAudioPlaybackScope? scope =
        context.dependOnInheritedWidgetOfExactType<EventChatAudioPlaybackScope>();
    assert(scope != null, 'EventChatAudioPlaybackScope not found in tree');
    return scope!.notifier!;
  }

  static EventChatAudioPlaybackController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<EventChatAudioPlaybackScope>()
        ?.notifier;
  }
}

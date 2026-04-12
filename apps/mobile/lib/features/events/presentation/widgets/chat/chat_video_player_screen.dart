import 'dart:async';
import 'dart:io';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_attachment_source.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

Future<void> openChatVideoPlayer(BuildContext context, {required String videoUrl}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext ctx) => ChatVideoPlayerScreen(videoUrl: videoUrl),
    ),
  );
}

class ChatVideoPlayerScreen extends StatefulWidget {
  const ChatVideoPlayerScreen({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<ChatVideoPlayerScreen> createState() => _ChatVideoPlayerScreenState();
}

class _ChatVideoPlayerScreenState extends State<ChatVideoPlayerScreen> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final VideoPlayerController ctrl = isEventChatRemoteAttachmentUrl(widget.videoUrl)
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl.trim()))
        : VideoPlayerController.file(File(eventChatAttachmentFilePath(widget.videoUrl)));
    try {
      await ctrl.initialize();
    } on Object {
      if (mounted) {
        setState(() => _failed = true);
      }
      await ctrl.dispose();
      return;
    }
    if (!mounted) {
      await ctrl.dispose();
      return;
    }
    _video = ctrl;
    _chewie = ChewieController(
      videoPlayerController: ctrl,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.white,
        handleColor: Colors.white,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white38,
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(context.l10n.eventChatVideoViewerTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ),
        body: Center(
          child: _failed
              ? const Icon(Icons.error_outline, color: Colors.white54, size: 48)
              : _chewie == null
                  ? const CircularProgressIndicator(color: Colors.white54)
                  : AspectRatio(
                      aspectRatio: _video!.value.aspectRatio,
                      child: Chewie(controller: _chewie!),
                    ),
        ),
      ),
    );
  }
}

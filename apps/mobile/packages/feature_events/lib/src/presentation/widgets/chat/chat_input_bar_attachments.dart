part of 'package:feature_events/src/presentation/widgets/chat/chat_input_bar.dart';

// State is split across part-file extensions on _ChatInputBarState; setState
// runs on that State instance, which the analyzer cannot see through here.
// ignore_for_file: invalid_use_of_protected_member
extension _ChatInputBarAttachments on _ChatInputBarState {
  void _showAttachmentMenu() {
    if (_mediaBlockedByNetwork()) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  margin: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              ChatInputBarAttachOptionRow(
                icon: CupertinoIcons.photo,
                label: context.l10n.eventChatAttachPhotoLibrary,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(ImageSource.gallery);
                },
              ),
              ChatInputBarAttachOptionRow(
                icon: CupertinoIcons.camera,
                label: context.l10n.eventChatAttachCamera,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(ImageSource.camera);
                },
              ),
              ChatInputBarAttachOptionRow(
                icon: CupertinoIcons.videocam,
                label: context.l10n.eventChatAttachVideo,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo();
                },
              ),
              ChatInputBarAttachOptionRow(
                icon: CupertinoIcons.doc,
                label: context.l10n.eventChatAttachDocument,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDocument();
                },
              ),
              ChatInputBarAttachOptionRow(
                icon: CupertinoIcons.music_note,
                label: context.l10n.eventChatAttachAudio,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAudio();
                },
              ),
              if (widget.onShareLocation != null)
                ChatInputBarAttachOptionRow(
                  icon: CupertinoIcons.location,
                  label: context.l10n.eventChatAttachLocation,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onShareLocation!();
                  },
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null || !mounted) return;
      if (widget.onSendImages != null) {
        await widget.onSendImages!(<XFile>[video]);
      }
    } on Object catch (_) {
      logEventsDiagnostic('chat_pick_video_failed');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>[
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
        ],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final PlatformFile pf = result.files.first;
      if (pf.path == null) return;
      if (widget.onSendImages != null) {
        await widget.onSendImages!(<XFile>[XFile(pf.path!, name: pf.name)]);
      }
    } on Object catch (_) {
      logEventsDiagnostic('chat_pick_document_failed');
    }
  }

  Future<void> _pickAudio() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['mp3', 'aac', 'm4a', 'ogg', 'wav'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final PlatformFile pf = result.files.first;
      if (pf.path == null) return;
      if (widget.onSendImages != null) {
        await widget.onSendImages!(<XFile>[XFile(pf.path!, name: pf.name)]);
      }
    } on Object catch (_) {
      logEventsDiagnostic('chat_pick_audio_failed');
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(limit: 5);
        if (images.isEmpty) return;
        setState(() {
          _stagedImages.addAll(images.take(5 - _stagedImages.length));
        });
      } else {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
        );
        if (photo == null) return;
        setState(() {
          if (_stagedImages.length < 5) _stagedImages.add(photo);
        });
      }
    } on Object catch (_) {
      logEventsDiagnostic('chat_pick_images_failed');
    }
  }

  Widget _buildThumbnailStrip() {
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _stagedImages.length,
            separatorBuilder: (BuildContext _, int _) =>
                const SizedBox(width: AppSpacing.xs),
            itemBuilder: (BuildContext context, int i) {
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: FutureBuilder<Uint8List>(
                      future: _stagedImages[i].readAsBytes(),
                      builder:
                          (BuildContext ctx, AsyncSnapshot<Uint8List> snap) {
                            if (snap.hasData) {
                              return Image.memory(
                                snap.data!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              width: 72,
                              height: 72,
                              color: AppColors.inputFill,
                            );
                          },
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => setState(() => _stagedImages.removeAt(i)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.appBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

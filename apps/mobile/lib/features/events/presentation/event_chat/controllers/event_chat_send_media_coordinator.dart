part of 'package:chisto_mobile/features/events/presentation/screens/event_chat_screen.dart';

/// Rounded-up seconds for display + API (upload does not return duration for audio).
int _eventChatVoiceDurationSeconds(Duration d) {
  if (d <= Duration.zero) {
    return 1;
  }
  final int sec = (d.inMilliseconds + 500) ~/ 1000;
  return sec < 1 ? 1 : sec;
}

extension EventChatSendMediaMixin on _EventChatScreenState {
    Future<void> _sendVoiceMessage(XFile file, Duration recordedLength) async {
      if (!_networkOnline) {
        if (!mounted) {
          return;
        }
        AppSnack.show(context, message: context.l10n.eventChatAttachmentsNeedNetwork);
        return;
      }
      final String clientMessageId = newChatClientMessageId();
      final String tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
      final int durSec = _eventChatVoiceDurationSeconds(recordedLength);
      final EventChatAttachment localAtt = EventChatAttachment(
        id: 'local_$tempId',
        url: file.path,
        mimeType: 'audio/m4a',
        fileName: file.name,
        sizeBytes: 0,
        duration: durSec,
      );
      final EventChatMessage optimistic = EventChatMessage(
        id: tempId,
        eventId: widget.eventId,
        authorId: _auth?.userId ?? 'me',
        authorName: _auth?.displayName ?? '…',
        createdAt: DateTime.now().toUtc(),
        body: null,
        isDeleted: false,
        isOwnMessage: true,
        replyToId: _replyTo?.id,
        replyToSnippet: _replyTo?.isDeleted == true ? null : _replyTo?.body,
        pending: true,
        messageType: EventChatMessageType.audio,
        attachments: <EventChatAttachment>[localAtt],
        clientMessageId: clientMessageId,
      );
      rebuildState(() {
        insertEventChatMessageSorted(_messages, optimistic);
        _replyTo = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      await _finalizeVoiceSend(tempId, file, recordedLength);
    }

    Future<void> _finalizeVoiceSend(String tempId, XFile file, Duration recordedLength) async {
      void clearUploadTracking() {
        _uploadProgressByTempId.remove(tempId);
        _uploadCancelRequested.remove(tempId);
      }

      try {
        final Uint8List bytes = await file.readAsBytes();
        if (!mounted) {
          return;
        }
        final String mime = ChatAttachmentMime.infer(file.name, bytes);
        rebuildState(() {
          _uploadProgressByTempId[tempId] = 0.0;
        });
        final List<EventChatAttachment> uploaded = await _repo.uploadAttachments(
          widget.eventId,
          <UploadableFile>[
            UploadableFile(
              bytes: bytes,
              fileName: file.name,
              mimeType: mime,
            ),
          ],
          onSendProgress: (int sent, int total) {
            if (!mounted || total <= 0) {
              return;
            }
            rebuildState(() {
              _uploadProgressByTempId[tempId] = sent / total;
            });
          },
          isCancelled: () => _uploadCancelRequested.contains(tempId),
        );
        if (!mounted) {
          return;
        }
        if (uploaded.isEmpty) {
          rebuildState(() {
            final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
            if (i >= 0) {
              _messages[i] = _messages[i].copyWith(pending: false, failed: true);
            }
            clearUploadTracking();
          });
          AppSnack.show(context, message: context.l10n.eventChatSendFailed);
          return;
        }
        final int voiceSec = _eventChatVoiceDurationSeconds(recordedLength);
        final EventChatAttachment u = uploaded.first;
        final EventChatAttachment withDuration = EventChatAttachment(
          id: u.id,
          url: u.url,
          mimeType: u.mimeType,
          fileName: u.fileName,
          sizeBytes: u.sizeBytes,
          width: u.width,
          height: u.height,
          duration: u.duration ?? voiceSec,
          thumbnailUrl: u.thumbnailUrl,
        );
        String? replyToId;
        String? clientMessageId;
        final int pendingRow = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (pendingRow >= 0) {
          replyToId = _messages[pendingRow].replyToId;
          clientMessageId = _messages[pendingRow].clientMessageId;
        }
        final EventChatMessage saved = await _repo.sendMessage(
          widget.eventId,
          '',
          replyToId: replyToId,
          attachments: <EventChatAttachment>[withDuration],
          clientMessageId: clientMessageId,
        );
        if (!mounted) {
          return;
        }
        rebuildState(() {
          final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
          if (i >= 0) {
            _messages[i] = saved;
          }
          _normalizeMessageList();
          clearUploadTracking();
        });
        chatDiagLog('voice_send_ok', <String, Object?>{'eventId': widget.eventId});
        unawaited(_markReadBestEffort());
      } on AppError catch (e) {
        if (!mounted) {
          return;
        }
        if (e.code == 'CANCELLED') {
          rebuildState(() {
            _messages.removeWhere((EventChatMessage m) => m.id == tempId);
            clearUploadTracking();
          });
          chatDiagLog('voice_upload_cancelled', <String, Object?>{'eventId': widget.eventId});
          return;
        }
        rebuildState(() {
          final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
          if (i >= 0) {
            _messages[i] = _messages[i].copyWith(pending: false, failed: true);
          }
          clearUploadTracking();
        });
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
      } on Object catch (_) {
        if (!mounted) {
          return;
        }
        rebuildState(() {
          final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
          if (i >= 0) {
            _messages[i] = _messages[i].copyWith(pending: false, failed: true);
          }
          clearUploadTracking();
        });
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
      }
    }

    /// Single video → [video]; all images → [image]; otherwise [file] (mixed gallery + doc).
    EventChatMessageType _messageTypeForAttachmentBatch(List<String> mimesLower) {
      if (mimesLower.isEmpty) {
        return EventChatMessageType.file;
      }
      final bool allImage = mimesLower.every((String m) => m.startsWith('image/'));
      if (allImage) {
        return EventChatMessageType.image;
      }
      if (mimesLower.length == 1) {
        final String m = mimesLower.first;
        if (m.startsWith('video/')) {
          return EventChatMessageType.video;
        }
      }
      return EventChatMessageType.file;
    }

    Future<void> _sendAttachments(List<dynamic> files) async {
      if (!_networkOnline) {
        if (!mounted) {
          return;
        }
        AppSnack.show(context, message: context.l10n.eventChatAttachmentsNeedNetwork);
        return;
      }
      if (files.isEmpty) {
        return;
      }
      final List<XFile> xFiles = <XFile>[];
      for (final dynamic f in files) {
        if (f is XFile) {
          xFiles.add(f);
        }
      }
      if (xFiles.isEmpty) {
        return;
      }
      if (xFiles.length > ChatUploadLimits.maxFilesPerMessage) {
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
        return;
      }

      final String clientMessageId = newChatClientMessageId();
      final String tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
      final List<EventChatAttachment> localAttachments = <EventChatAttachment>[];
      final List<String> mimesLower = <String>[];
      for (int i = 0; i < xFiles.length; i++) {
        final XFile f = xFiles[i];
        final Uint8List bytes = await f.readAsBytes();
        if (!mounted) {
          return;
        }
        final String name = f.name;
        final String mime = ChatAttachmentMime.infer(name, bytes);
        final String ml = mime.toLowerCase();
        if (!ChatUploadLimits.isAllowedMime(ml)) {
          AppSnack.show(context, message: context.l10n.eventChatSendFailed);
          return;
        }
        if (bytes.length > ChatUploadLimits.maxBytesForMime(ml)) {
          AppSnack.show(context, message: context.l10n.eventChatSendFailed);
          return;
        }
        mimesLower.add(ml);
        localAttachments.add(
          EventChatAttachment(
            id: 'local_${tempId}_$i',
            url: f.path,
            mimeType: mime,
            fileName: name,
            sizeBytes: bytes.length,
          ),
        );
      }

      final EventChatMessage optimistic = EventChatMessage(
        id: tempId,
        eventId: widget.eventId,
        authorId: _auth?.userId ?? 'me',
        authorName: _auth?.displayName ?? '…',
        createdAt: DateTime.now().toUtc(),
        body: null,
        isDeleted: false,
        isOwnMessage: true,
        replyToId: _replyTo?.id,
        replyToSnippet: _replyTo?.isDeleted == true ? null : _replyTo?.body,
        pending: true,
        messageType: _messageTypeForAttachmentBatch(mimesLower),
        attachments: localAttachments,
        clientMessageId: clientMessageId,
      );
      rebuildState(() {
        insertEventChatMessageSorted(_messages, optimistic);
        _replyTo = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      if (!mounted) {
        return;
      }
      await _finalizeAttachmentSend(tempId, xFiles);
    }

    Future<void> _finalizeAttachmentSend(String tempId, List<XFile> xFiles) async {
      void clearUploadTracking() {
        _uploadProgressByTempId.remove(tempId);
        _uploadCancelRequested.remove(tempId);
      }

      try {
        final List<UploadableFile> uploadable = <UploadableFile>[];
        for (final XFile f in xFiles) {
          final Uint8List bytes = await f.readAsBytes();
          final String name = f.name;
          uploadable.add(
            UploadableFile(
              bytes: bytes,
              fileName: name,
              mimeType: ChatAttachmentMime.infer(name, bytes),
            ),
          );
        }
        if (!mounted) {
          return;
        }
        rebuildState(() {
          _uploadProgressByTempId[tempId] = 0.0;
        });
        final List<EventChatAttachment> uploaded = await _repo.uploadAttachments(
          widget.eventId,
          uploadable,
          onSendProgress: (int sent, int total) {
            if (!mounted || total <= 0) {
              return;
            }
            rebuildState(() {
              _uploadProgressByTempId[tempId] = sent / total;
            });
          },
          isCancelled: () => _uploadCancelRequested.contains(tempId),
        );
        if (!mounted) {
          return;
        }
        if (uploaded.isEmpty) {
          rebuildState(() {
            final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
            if (i >= 0) {
              _messages[i] = _messages[i].copyWith(pending: false, failed: true);
            }
            clearUploadTracking();
          });
          AppSnack.show(context, message: context.l10n.eventChatSendFailed);
          return;
        }
        String? replyToId;
        String? clientMessageId;
        final int pendingRow = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
        if (pendingRow >= 0) {
          replyToId = _messages[pendingRow].replyToId;
          clientMessageId = _messages[pendingRow].clientMessageId;
        }
        final EventChatMessage saved = await _repo.sendMessage(
          widget.eventId,
          '',
          replyToId: replyToId,
          attachments: uploaded,
          clientMessageId: clientMessageId,
        );
        if (!mounted) {
          return;
        }
        rebuildState(() {
          final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
          if (i >= 0) {
            _messages[i] = saved;
          }
          _normalizeMessageList();
          clearUploadTracking();
        });
        chatDiagLog('attachment_send_ok', <String, Object?>{'eventId': widget.eventId});
        unawaited(_markReadBestEffort());
      } on AppError catch (e) {
        if (!mounted) {
          return;
        }
        if (e.code == 'CANCELLED') {
          rebuildState(() {
            _messages.removeWhere((EventChatMessage m) => m.id == tempId);
            clearUploadTracking();
          });
          chatDiagLog('attachment_upload_cancelled', <String, Object?>{'eventId': widget.eventId});
          return;
        }
        rebuildState(() {
          final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
          if (i >= 0) {
            _messages[i] = _messages[i].copyWith(pending: false, failed: true);
          }
          clearUploadTracking();
        });
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
      } on Object catch (_) {
        if (!mounted) {
          return;
        }
        rebuildState(() {
          final int i = _messages.indexWhere((EventChatMessage m) => m.id == tempId);
          if (i >= 0) {
            _messages[i] = _messages[i].copyWith(pending: false, failed: true);
          }
          clearUploadTracking();
        });
        AppSnack.show(context, message: context.l10n.eventChatSendFailed);
      }
    }
}

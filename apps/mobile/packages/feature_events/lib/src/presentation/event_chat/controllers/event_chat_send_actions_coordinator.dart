part of 'package:feature_events/src/presentation/screens/event_chat_screen.dart';

extension EventChatSendActionsMixin on _EventChatScreenState {
  Future<void> _openLocationPicker() async {
    if (!_networkOnline) {
      AppSnack.show(
        context,
        message: context.l10n.eventChatAttachmentsNeedNetwork,
      );
      return;
    }
    final Map<String, dynamic>? result =
        await AppBottomSheet.show<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.panelBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          builder: (BuildContext ctx) {
            return const ChatLocationPickerSheet();
          },
        );
    if (result == null || !mounted) return;
    final double? lat = result['lat'] as double?;
    final double? lng = result['lng'] as double?;
    final String? label = result['label'] as String?;
    if (lat == null || lng == null) return;

    final String body = label ?? context.l10n.chatSharedLocation;
    final String clientMessageId = newChatClientMessageId();
    final String tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final EventChatMessage optimistic = EventChatMessage(
      id: tempId,
      eventId: widget.eventId,
      authorId: _auth.userId ?? 'me',
      authorName: _auth.displayName ?? '…',
      createdAt: DateTime.now().toUtc(),
      body: body,
      isDeleted: false,
      isOwnMessage: true,
      pending: true,
      messageType: EventChatMessageType.location,
      locationLat: lat,
      locationLng: lng,
      locationLabel: label,
      clientMessageId: clientMessageId,
    );
    rebuildState(() => insertEventChatMessageSorted(_messages, optimistic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    try {
      final EventChatMessage saved = await _repo.sendMessage(
        widget.eventId,
        body,
        locationLat: lat,
        locationLng: lng,
        locationLabel: label,
        clientMessageId: clientMessageId,
      );
      if (!mounted) return;
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage m) => m.id == tempId,
        );
        if (i >= 0) {
          _messages[i] = saved;
        }
        _normalizeMessageList();
      });
      unawaited(_markReadBestEffort());
    } on Object catch (_) {
      if (!mounted) return;
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage m) => m.id == tempId,
        );
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
      });
      AppSnack.show(context, message: context.l10n.eventChatSendFailed);
    }
  }

  Future<void> _send(String text) async {
    final String t = text.trim();
    if (t.isEmpty || t.length > 2000) {
      return;
    }
    if (_editing != null) {
      await _submitEdit(t);
      return;
    }
    final String clientMessageId = newChatClientMessageId();
    final String tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final EventChatMessage optimistic = EventChatMessage(
      id: tempId,
      eventId: widget.eventId,
      authorId: _auth.userId ?? 'me',
      authorName: _auth.displayName ?? '…',
      createdAt: DateTime.now().toUtc(),
      body: t,
      isDeleted: false,
      isOwnMessage: true,
      replyToId: _replyTo?.id,
      replyToSnippet: _replyTo?.isDeleted ?? false ? null : _replyTo?.body,
      pending: true,
      messageType: EventChatMessageType.text,
      clientMessageId: clientMessageId,
    );
    rebuildState(() {
      insertEventChatMessageSorted(_messages, optimistic);
      _replyTo = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    try {
      final EventChatMessage saved = await _repo.sendMessage(
        widget.eventId,
        t,
        replyToId: optimistic.replyToId,
        clientMessageId: clientMessageId,
      );
      if (!mounted) {
        return;
      }
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage m) => m.id == tempId,
        );
        if (i >= 0) {
          _messages[i] = saved;
        }
        // SSE may have delivered this message while the POST was in-flight.
        // Remove any duplicate that shares the server ID.
        _normalizeMessageList();
      });
      unawaited(_markReadBestEffort());
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      String snackMsg = localizedAppErrorMessage(context.l10n, e);
      if (_shouldQueueOffline(e)) {
        final bool queued = await ChatOutboxStore.shared.enqueueText(
          eventId: widget.eventId,
          tempId: tempId,
          clientMessageId: clientMessageId,
          body: t,
          replyToId: optimistic.replyToId,
        );
        if (!mounted) {
          return;
        }
        if (queued) {
          return;
        }
        final bool full = await ChatOutboxStore.shared.isOutboxFullForEvent(
          widget.eventId,
        );
        if (!mounted) {
          return;
        }
        if (full) {
          snackMsg = context.l10n.eventsChatOutboxFull(
            ChatOutboxStore.maxPendingTextRowsPerEvent,
          );
        }
      }
      if (!mounted) {
        return;
      }
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage m) => m.id == tempId,
        );
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
      });
      AppSnack.show(context, message: snackMsg);
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      final bool queued = await ChatOutboxStore.shared.enqueueText(
        eventId: widget.eventId,
        tempId: tempId,
        clientMessageId: clientMessageId,
        body: t,
        replyToId: optimistic.replyToId,
      );
      if (!mounted) {
        return;
      }
      if (queued) {
        return;
      }
      final bool full = await ChatOutboxStore.shared.isOutboxFullForEvent(
        widget.eventId,
      );
      if (!mounted) {
        return;
      }
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage m) => m.id == tempId,
        );
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
      });
      if (full) {
        AppSnack.show(
          context,
          message: context.l10n.eventsChatOutboxFull(
            ChatOutboxStore.maxPendingTextRowsPerEvent,
          ),
        );
      }
    }
  }

  Future<void> _submitEdit(String text) async {
    final EventChatMessage? ed = _editing;
    if (ed == null) {
      return;
    }
    final String t = text.trim();
    if (t.isEmpty) {
      return;
    }
    rebuildState(() => _editing = null);
    try {
      final EventChatMessage saved = await _repo.editMessage(
        widget.eventId,
        ed.id,
        t,
      );
      if (!mounted) {
        return;
      }
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage m) => m.id == ed.id,
        );
        if (i >= 0) {
          _messages[i] = saved;
        }
      });
    } on AppError catch (e) {
      if (mounted) {
        rebuildState(() => _editing = ed);
        AppSnack.failure(context, error: e);
      }
    } on Object catch (_) {
      if (mounted) {
        rebuildState(() => _editing = ed);
        AppSnack.show(context, message: context.l10n.eventChatLoadError);
      }
    }
  }

  Future<void> _retryFailed(EventChatMessage m) async {
    if (!m.failed) {
      return;
    }
    if (m.messageType == EventChatMessageType.audio &&
        m.attachments.length == 1) {
      final String raw = m.attachments.first.url.trim();
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return;
      }
      final String path = raw.startsWith('file://')
          ? Uri.parse(raw).toFilePath()
          : raw;
      final String name = m.attachments.first.fileName.isEmpty
          ? 'voice.m4a'
          : m.attachments.first.fileName;
      final XFile file = XFile(path, name: name);
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage x) => x.id == m.id,
        );
        if (i >= 0) {
          _messages[i] = m.copyWith(pending: true, failed: false);
        }
      });
      final int sec = m.attachments.first.duration ?? 1;
      await _finalizeVoiceSend(m.id, file, Duration(seconds: sec));
      return;
    }
    if ((m.messageType == EventChatMessageType.image ||
            m.messageType == EventChatMessageType.file ||
            m.messageType == EventChatMessageType.video) &&
        m.attachments.isNotEmpty) {
      final bool allLocal = m.attachments.every(
        (EventChatAttachment a) => !isEventChatRemoteAttachmentUrl(a.url),
      );
      if (!allLocal) {
        return;
      }
      final List<XFile> xFiles = <XFile>[];
      for (final EventChatAttachment a in m.attachments) {
        final String path = eventChatAttachmentFilePath(a.url);
        final String name = a.fileName.isEmpty ? 'attachment' : a.fileName;
        xFiles.add(XFile(path, name: name));
      }
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage x) => x.id == m.id,
        );
        if (i >= 0) {
          _messages[i] = m.copyWith(pending: true, failed: false);
        }
      });
      await _finalizeAttachmentSend(m.id, xFiles);
      return;
    }
    if (m.body == null) {
      return;
    }
    final String t = m.body!;
    rebuildState(() {
      final int i = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
      if (i >= 0) {
        _messages[i] = m.copyWith(pending: true, failed: false);
      }
    });
    try {
      final EventChatMessage saved = await _repo.sendMessage(
        widget.eventId,
        t,
        replyToId: m.replyToId,
        clientMessageId: m.clientMessageId ?? newChatClientMessageId(),
      );
      if (!mounted) {
        return;
      }
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage x) => x.id == m.id,
        );
        if (i >= 0) {
          _messages[i] = saved;
        }
      });
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage x) => x.id == m.id,
        );
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(pending: false, failed: true);
        }
      });
    }
  }

  Future<void> _delete(EventChatMessage m) async {
    try {
      await _repo.deleteMessage(widget.eventId, m.id);
      if (!mounted) {
        return;
      }
      if (_audioPlayback.activeClipKey == m.id) {
        await _audioPlayback.stopActiveClip();
      }
      rebuildState(() {
        final int i = _messages.indexWhere(
          (EventChatMessage x) => x.id == m.id,
        );
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(
            isDeleted: true,
            body: null,
            isPinned: false,
            attachments: const <EventChatAttachment>[],
            locationLat: null,
            locationLng: null,
            locationLabel: null,
          );
        }
      });
      unawaited(_loadPinned());
    } on Object catch (_) {
      if (mounted) {
        AppSnack.show(context, message: context.l10n.eventChatLoadError);
      }
    }
  }

  Future<void> _togglePin(EventChatMessage m, bool pin) async {
    final int idx = _messages.indexWhere((EventChatMessage x) => x.id == m.id);
    if (idx >= 0) {
      rebuildState(
        () => _messages[idx] = _messages[idx].copyWith(isPinned: pin),
      );
    }
    try {
      await _repo.setPin(widget.eventId, m.id, pinned: pin);
      if (!mounted) {
        return;
      }
      unawaited(_loadPinned());
      if (!pin) {
        AppSnack.show(context, message: context.l10n.eventChatUnpinConfirm);
      }
    } on AppError catch (e) {
      if (mounted) {
        if (idx >= 0 && idx < _messages.length && _messages[idx].id == m.id) {
          rebuildState(
            () => _messages[idx] = _messages[idx].copyWith(isPinned: !pin),
          );
        }
        AppSnack.failure(context, error: e);
      }
    } on Object catch (_) {
      if (mounted) {
        if (idx >= 0 && idx < _messages.length && _messages[idx].id == m.id) {
          rebuildState(
            () => _messages[idx] = _messages[idx].copyWith(isPinned: !pin),
          );
        }
        AppSnack.show(context, message: context.l10n.eventChatLoadError);
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_muteBusy) {
      return;
    }
    final bool next = !_muted;
    rebuildState(() {
      _muted = next;
      _muteBusy = true;
    });
    try {
      await _repo.setMuteStatus(widget.eventId, next);
      if (mounted) {
        AppSnack.show(
          context,
          message: next
              ? context.l10n.eventChatMuted
              : context.l10n.eventChatUnmuted,
        );
      }
    } on Object catch (_) {
      if (mounted) {
        rebuildState(() => _muted = !next);
        AppSnack.show(context, message: context.l10n.eventChatLoadError);
      }
    } finally {
      if (mounted) {
        rebuildState(() => _muteBusy = false);
      }
    }
  }
}

part of 'package:chisto_mobile/features/events/presentation/screens/event_chat_screen.dart';

extension EventChatScrollMixin on _EventChatScreenState {
    void _onScroll() {
      if (!_scroll.hasClients) {
        return;
      }
      final ScrollPosition p = _scroll.position;
      // Only load older when the user has scrolled away from the bottom (newest) anchor
      // and is within [threshold] of the top (oldest) edge. A naive
      // "pixels >= maxScrollExtent - threshold" is true at the bottom when max is small
      // (e.g. 0 >= 50 - 120), which spams _loadOlder and breaks tests.
      const double threshold = 120;
      if (p.maxScrollExtent > p.minScrollExtent) {
        final double distFromOldestEdge = p.maxScrollExtent - p.pixels;
        if (distFromOldestEdge <= threshold && p.pixels > p.minScrollExtent + 0.5) {
          unawaited(_loadOlder());
        }
      }
      if (p.pixels <= 80) {
        if (_showNewPill) {
          rebuildState(() => _showNewPill = false);
        }
      }
    }

    bool get _nearBottom {
      if (!_scroll.hasClients) {
        return true;
      }
      return _scroll.position.pixels <= 80;
    }

    void _scrollToBottom({bool animated = true}) {
      if (!_scroll.hasClients) {
        return;
      }
      final double target = _scroll.position.minScrollExtent;
      if (animated) {
        _scroll.animateTo(
          target,
          duration: AppMotion.medium,
          curve: AppMotion.smooth,
        );
      } else {
        _scroll.jumpTo(target);
      }
    }

    GlobalKey _keyFor(String id) => _bubbleKeys.putIfAbsent(id, GlobalKey.new);

    void _pruneBubbleKeys() {
      final Set<String> ids = _messages.map((EventChatMessage m) => m.id).toSet();
      _bubbleKeys.removeWhere((String id, GlobalKey _) => !ids.contains(id));
    }

    /// Only the first row per message id may hold the scroll [GlobalKey].
    bool _isCanonicalBubbleIndex(int index) {
      if (index < 0 || index >= _messages.length) {
        return false;
      }
      final String id = _messages[index].id;
      return _messages.indexWhere((EventChatMessage m) => m.id == id) == index;
    }

    void _scrollToMessageId(String id) {
      final GlobalKey? g = _bubbleKeys[id];
      final BuildContext? ctx = g?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: AppMotion.standard,
          curve: AppMotion.smooth,
          alignment: 0.35,
        );
        rebuildState(() => _highlightId = id);
        _highlightTimer?.cancel();
        _highlightTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) {
            rebuildState(() => _highlightId = null);
          }
        });
      } else {
        AppSnack.show(context, message: context.l10n.eventChatMessageNotInView);
      }
    }
}

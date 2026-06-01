part of 'package:feature_events/src/presentation/screens/event_chat_screen.dart';

extension EventChatSearchMixin on _EventChatScreenState {
  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    final String q = text.trim();
    if (q.length < 2) {
      _searchSerial++;
      if (_searchServerHits.isNotEmpty ||
          _searchError ||
          _searchLoading ||
          _lastSearchQuery.isNotEmpty) {
        rebuildState(() {
          _searchServerHits = <EventChatMessage>[];
          _searchCursor = null;
          _searchHasMore = false;
          _searchError = false;
          _searchLoading = false;
          _lastSearchQuery = '';
        });
      }
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_runSearch(q));
    });
  }

  Future<void> _runSearch(String q, {bool loadMore = false}) async {
    final String trimmed = q.trim();
    if (trimmed.length < 2) {
      return;
    }
    if (!loadMore) {
      _searchSerial++;
      final int serial = _searchSerial;
      _lastSearchQuery = trimmed;
      rebuildState(() {
        _searchLoading = true;
        _searchError = false;
        _searchServerHits = <EventChatMessage>[];
        _searchCursor = null;
        _searchHasMore = false;
      });
      await _executeSearchRequest(trimmed, serial, loadMore: false);
    } else {
      if (_lastSearchQuery.length < 2) {
        return;
      }
      rebuildState(() => _searchLoading = true);
      await _executeSearchRequest(
        _lastSearchQuery.trim(),
        _searchSerial,
        loadMore: true,
      );
    }
  }

  Future<void> _executeSearchRequest(
    String trimmed,
    int serial, {
    required bool loadMore,
  }) async {
    try {
      final EventChatFetchResult r = await _repo.searchMessages(
        widget.eventId,
        trimmed,
        limit: 30,
        cursor: loadMore ? _searchCursor : null,
      );
      if (!mounted || _searchSerial != serial) {
        return;
      }
      if (_lastSearchQuery != trimmed) {
        return;
      }
      rebuildState(() {
        _searchError = false;
        if (loadMore) {
          final List<EventChatMessage> next = List<EventChatMessage>.from(
            _searchServerHits,
          )..addAll(r.messages.reversed);
          _searchServerHits = next;
        } else {
          _searchServerHits = List<EventChatMessage>.from(r.messages.reversed);
        }
        _searchCursor = r.nextCursor;
        _searchHasMore = r.hasMore;
      });
    } on Object catch (_) {
      if (!mounted || _searchSerial != serial) {
        return;
      }
      rebuildState(() {
        _searchError = true;
        if (!loadMore) {
          _searchServerHits = <EventChatMessage>[];
        }
      });
    } finally {
      if (mounted && _searchSerial == serial) {
        rebuildState(() {
          _searchLoading = false;
        });
      }
    }
  }

  List<EventChatMessage> _mergedSearchHits() {
    return mergeEventChatSearchHits(
      serverHits: _searchServerHits,
      allMessages: _messages,
      query: _lastSearchQuery,
    );
  }

  Widget _buildSearchPanel(BuildContext context) {
    final List<EventChatMessage> merged = _mergedSearchHits();
    final bool showLocalBanner =
        !_searchLoading &&
        _lastSearchQuery.length >= 2 &&
        eventChatSearchMergedIncludesLocalOnly(
          serverHits: _searchServerHits,
          merged: merged,
        );
    return EventChatSearchPanel(
      searchLoading: _searchLoading,
      searchError: _searchError,
      lastSearchQuery: _lastSearchQuery,
      searchHasMore: _searchHasMore,
      merged: merged,
      showLocalBanner: showLocalBanner,
      onRetrySearch: () => _runSearch(_lastSearchQuery),
      onLoadMoreSearch: () => _runSearch(_lastSearchQuery, loadMore: true),
      onSelectHit: (EventChatMessage m) {
        _searchSerial++;
        rebuildState(() {
          _searchOpen = false;
          _searchServerHits = <EventChatMessage>[];
          _searchController.clear();
          _searchDebounce?.cancel();
          _lastSearchQuery = '';
          _searchError = false;
        });
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToMessageId(m.id),
        );
      },
    );
  }

  void _rebuildGrouping() {
    _grouping = computeEventChatMessageGrouping(_messages);
  }
}

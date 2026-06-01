/// Remote text search phases for the events discovery feed (debounced list refresh).
enum EventsSearchRemotePhase { idle, loading, ready, error }

/// Immutable remote search phase for the events discovery feed.
class EventsSearchState {
  const EventsSearchState({
    this.phase = EventsSearchRemotePhase.idle,
    this.lastError,
  });

  final EventsSearchRemotePhase phase;
  final Object? lastError;

  EventsSearchState copyWith({
    EventsSearchRemotePhase? phase,
    Object? lastError,
    bool clearLastError = false,
  }) {
    return EventsSearchState(
      phase: phase ?? this.phase,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}

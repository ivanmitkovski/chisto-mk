/// Tracks which event chat screen is foregrounded (suppresses duplicate push banners).
class EventChatForegroundScope {
  EventChatForegroundScope._();

  static final EventChatForegroundScope instance = EventChatForegroundScope._();

  String? _activeEventId;

  String? get activeEventId => _activeEventId;

  void setActiveEventId(String? eventId) {
    _activeEventId = eventId?.trim().isNotEmpty ?? false ? eventId : null;
  }

  bool isViewingEvent(String eventId) =>
      _activeEventId != null && _activeEventId == eventId;
}

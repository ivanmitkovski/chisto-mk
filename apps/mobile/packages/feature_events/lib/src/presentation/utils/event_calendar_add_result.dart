/// Outcome of asking the OS to add an event to the user's calendar.
enum EventCalendarAddResult {
  /// Native calendar UI opened and the flow completed successfully.
  added,

  /// We already recorded this event (same schedule) as added on this device.
  alreadyAdded,

  /// User dismissed the calendar UI or the platform returned failure without error.
  cancelled,

  /// Platform error or plugin failure.
  failed,
}

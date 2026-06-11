/// Where a notification navigation request originated.
enum NotificationNavigationOrigin {
  /// User opened the in-app notifications list and tapped an item.
  inbox,

  /// Push tap, cold start, deep link, or other external entry.
  external,
}

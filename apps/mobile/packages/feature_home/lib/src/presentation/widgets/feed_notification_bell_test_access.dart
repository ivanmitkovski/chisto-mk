part of 'feed_notification_bell.dart';

/// Test-only accessors for [FeedNotificationBellState] animation wiring.
extension FeedNotificationBellStateTestAccess on FeedNotificationBellState {
  @visibleForTesting
  AnimationController get testSwingController => _swingController;

  @visibleForTesting
  Animation<double> get testSwingRotation => _swingRotation;
}

/// Peak swing angle in radians (~14°) for tests.
@visibleForTesting
double feedNotificationBellPeakSwingRadians() => 0.24;

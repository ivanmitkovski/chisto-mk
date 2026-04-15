/// Stagger delays (milliseconds added to [AppMotion.standard]) for
/// [StaggeredSection] children in [DetailContent].
///
/// Values are multiples of 5ms so small adjustments stay visually coherent.
abstract final class EventDetailStagger {
  static const int title = 0;
  static const int cancelledBanner = 15;
  static const int maxParticipantsBanner = 20;
  static const int eventFullBanner = 25;
  static const int completedCallouts = 30;
  static const int groupedPanel = 60;
  static const int weather = 90;
  static const int gear = 100;
  static const int description = 130;
  static const int participationBlock = 140;
  static const int participants = 155;
  static const int organizer = 175;
  static const int organizerAnalytics = 185;
  static const int afterPhotos = 185;
  static const int impactSummary = 190;
}

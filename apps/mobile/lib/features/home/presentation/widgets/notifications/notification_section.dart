import 'package:chisto_mobile/features/home/domain/models/feed_notification.dart';

class NotificationSection {
  const NotificationSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<FeedNotification> items;
}

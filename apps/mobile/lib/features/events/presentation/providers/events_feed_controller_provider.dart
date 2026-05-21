import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/presentation/controllers/events_feed_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Discovery feed controller for the Events tab ([EventsFeedScreen] watches this).
final eventsFeedControllerProvider = Provider<EventsFeedController>((Ref ref) {
  final EventsFeedController controller = EventsFeedController(
    repository: EventsRepositoryRegistry.instance,
  );
  ref.onDispose(controller.dispose);
  return controller;
});

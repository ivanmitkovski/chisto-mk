import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:flutter/foundation.dart';

abstract class EventsRepository implements Listenable {
  List<EcoEvent> get events;

  bool get isReady;
  Future<void> get ready;

  void loadInitialIfNeeded();
  void resetToSeed();

  EcoEvent? findById(String id);
  EcoEvent? findBySiteAndTitle({
    required String siteId,
    required String title,
  });

  void create(EcoEvent event);
  bool updateStatus(String id, EcoEventStatus status);
  bool toggleJoin(String id);

  bool setCheckInOpen({
    required String eventId,
    required bool isOpen,
  });

  bool rotateCheckInSession({
    required String eventId,
    required String sessionId,
  });

  bool setCheckedInCount({
    required String eventId,
    required int checkedInCount,
  });

  bool setAttendeeCheckInStatus({
    required String eventId,
    required AttendeeCheckInStatus status,
    DateTime? checkedInAt,
  });

  bool setReminder({
    required String eventId,
    required bool enabled,
    DateTime? reminderAt,
  });

  bool setAfterImages({
    required String eventId,
    required List<String> imagePaths,
  });
}

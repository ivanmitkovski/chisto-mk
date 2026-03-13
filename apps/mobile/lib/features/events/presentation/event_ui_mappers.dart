import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

extension EcoEventCategoryUI on EcoEventCategory {
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}

extension EventGearUI on EventGear {
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}

extension EventDifficultyUI on EventDifficulty {
  Color get color => Color(colorValue);
}

extension EcoEventStatusUI on EcoEventStatus {
  Color get color => Color(colorValue);
}

extension EventTimeUI on EventTime {
  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  static EventTime fromTimeOfDay(TimeOfDay tod) =>
      EventTime(hour: tod.hour, minute: tod.minute);
}

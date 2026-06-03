import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:flutter/material.dart';

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

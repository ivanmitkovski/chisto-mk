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

extension EcoEventCategoryUI on EcoEventCategory {
  IconData get icon => switch (this) {
    EcoEventCategory.generalCleanup => Icons.cleaning_services_outlined,
    EcoEventCategory.riverAndLake => Icons.water_outlined,
    EcoEventCategory.treeAndGreen => Icons.park_outlined,
    EcoEventCategory.recyclingDrive => Icons.recycling_outlined,
    EcoEventCategory.hazardousRemoval => Icons.warning_amber_outlined,
    EcoEventCategory.awarenessAndEducation => Icons.campaign_outlined,
    EcoEventCategory.other => Icons.more_horiz,
  };
}

extension EventGearUI on EventGear {
  IconData get icon => switch (this) {
    EventGear.trashBags => Icons.shopping_bag_outlined,
    EventGear.gloves => Icons.back_hand_outlined,
    EventGear.rakes => Icons.agriculture_outlined,
    EventGear.wheelbarrow => Icons.construction_outlined,
    EventGear.waterBoots => Icons.water_drop_outlined,
    EventGear.safetyVest => Icons.security_outlined,
    EventGear.firstAid => Icons.medical_services_outlined,
    EventGear.sunscreen => Icons.wb_sunny_outlined,
  };
}

import 'package:flutter/material.dart';

enum EcoEventCategory {
  generalCleanup(
    'General cleanup',
    'Pick up litter, sweep debris, and restore the area.',
    IconData(0xf643, fontFamily: 'MaterialIcons'),
  ),
  riverAndLake(
    'River & lake cleanup',
    'Remove waste from waterways, shores, and drainage channels.',
    IconData(0xf02a6, fontFamily: 'MaterialIcons'),
  ),
  treeAndGreen(
    'Tree planting & greening',
    'Plant trees, restore green spaces, and build garden beds.',
    IconData(0xf004e, fontFamily: 'MaterialIcons'),
  ),
  recyclingDrive(
    'Recycling drive',
    'Sort, collect, and transport recyclables to processing centers.',
    IconData(0xf0370, fontFamily: 'MaterialIcons'),
  ),
  hazardousRemoval(
    'Hazardous waste removal',
    'Safely collect chemicals, tires, batteries, or asbestos.',
    IconData(0xf02a0, fontFamily: 'MaterialIcons'),
  ),
  awarenessAndEducation(
    'Awareness & education',
    'Workshops, talks, or community engagement on eco practices.',
    IconData(0xf012e, fontFamily: 'MaterialIcons'),
  ),
  other(
    'Other',
    "Custom event that doesn't match the categories above.",
    IconData(0xf8d9, fontFamily: 'MaterialIcons'),
  );

  const EcoEventCategory(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;

  /// The camelCase key sent to/received from the API `category` query param.
  String get key => name;
}

enum EventGear {
  trashBags('Trash bags', IconData(0xf37d, fontFamily: 'MaterialIcons')),
  gloves('Gloves', IconData(0xf05c0, fontFamily: 'MaterialIcons')),
  rakes('Rakes & shovels', IconData(0xf7be, fontFamily: 'MaterialIcons')),
  wheelbarrow('Wheelbarrow', IconData(0xf06f2, fontFamily: 'MaterialIcons')),
  waterBoots('Water boots', IconData(0xefde, fontFamily: 'MaterialIcons')),
  safetyVest('Safety vest', IconData(0xf379, fontFamily: 'MaterialIcons')),
  firstAid('First aid kit', IconData(0xf1be, fontFamily: 'MaterialIcons')),
  sunscreen('Sunscreen & water', IconData(0xf4bc, fontFamily: 'MaterialIcons'));

  const EventGear(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum CleanupScale {
  small('Small (1–5 people)', 'Quick spot cleanup, one bag or two.'),
  medium('Medium (6–15 people)', 'Half-day effort, several areas covered.'),
  large('Large (16–40 people)', 'Organized group, heavy waste removal.'),
  massive('Massive (40+ people)', 'City-wide or multi-site event.');

  const CleanupScale(this.label, this.description);
  final String label;
  final String description;
}

enum EventDifficulty {
  easy('Easy', 'Flat terrain, light waste, family-friendly.', 0xFF2FD788),
  moderate(
    'Moderate',
    'Mixed terrain or bulky items, some effort.',
    0xFFF5A623,
  ),
  hard(
    'Hard',
    'Steep slopes, heavy debris, or hazardous materials.',
    0xFFE6513D,
  );

  const EventDifficulty(this.label, this.description, this.colorValue);
  final String label;
  final String description;
  final int colorValue;
}

enum EcoEventStatus {
  upcoming('Upcoming', 0xFF2FD788),
  inProgress('In progress', 0xFF3BA3F7),
  completed('Completed', 0xFF7A7A7A),
  cancelled('Cancelled', 0xFFE6513D);

  const EcoEventStatus(this.label, this.colorValue);
  final String label;
  final int colorValue;

  /// The camelCase lifecycle key accepted by the `status=` query param.
  String get apiKey => name;
}

/// Server moderation lifecycle: pending → approved or declined.
/// Declined events can be edited and resubmitted by the organizer.
enum ModerationStatus {
  pending,
  approved,
  declined;

  static ModerationStatus fromBoolAndString({
    required bool moderationApproved,
    String? moderationStatusRaw,
  }) {
    if (moderationStatusRaw != null) {
      for (final ModerationStatus v in ModerationStatus.values) {
        if (v.name == moderationStatusRaw) return v;
      }
    }
    return moderationApproved
        ? ModerationStatus.approved
        : ModerationStatus.pending;
  }
}

enum AttendeeCheckInStatus { notCheckedIn, checkedIn }

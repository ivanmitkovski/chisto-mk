enum EcoEventCategory {
  generalCleanup(
    'General cleanup',
    'Pick up litter, sweep debris, and restore the area.',
    0xf643,
  ),
  riverAndLake(
    'River & lake cleanup',
    'Remove waste from waterways, shores, and drainage channels.',
    0xf02a6,
  ),
  treeAndGreen(
    'Tree planting & greening',
    'Plant trees, restore green spaces, and build garden beds.',
    0xf004e,
  ),
  recyclingDrive(
    'Recycling drive',
    'Sort, collect, and transport recyclables to processing centers.',
    0xf0370,
  ),
  hazardousRemoval(
    'Hazardous waste removal',
    'Safely collect chemicals, tires, batteries, or asbestos.',
    0xf02a0,
  ),
  awarenessAndEducation(
    'Awareness & education',
    'Workshops, talks, or community engagement on eco practices.',
    0xf012e,
  ),
  other(
    'Other',
    "Custom event that doesn't match the categories above.",
    0xf8d9,
  );

  const EcoEventCategory(this.label, this.description, this.iconCodePoint);
  final String label;
  final String description;
  final int iconCodePoint;

  /// The camelCase key sent to/received from the API `category` query param.
  String get key => name;
}

enum EventGear {
  trashBags('Trash bags', 0xf37d),
  gloves('Gloves', 0xf05c0),
  rakes('Rakes & shovels', 0xf7be),
  wheelbarrow('Wheelbarrow', 0xf06f2),
  waterBoots('Water boots', 0xefde),
  safetyVest('Safety vest', 0xf379),
  firstAid('First aid kit', 0xf1be),
  sunscreen('Sunscreen & water', 0xf4bc);

  const EventGear(this.label, this.iconCodePoint);
  final String label;
  final int iconCodePoint;
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

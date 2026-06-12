enum EcoEventCategory {
  generalCleanup(
    'General cleanup',
    'Pick up litter, sweep debris, and restore the area.',
  ),
  riverAndLake(
    'River & lake cleanup',
    'Remove waste from waterways, shores, and drainage channels.',
  ),
  treeAndGreen(
    'Tree planting & greening',
    'Plant trees, restore green spaces, and build garden beds.',
  ),
  recyclingDrive(
    'Recycling drive',
    'Sort, collect, and transport recyclables to processing centers.',
  ),
  hazardousRemoval(
    'Hazardous waste removal',
    'Safely collect chemicals, tires, batteries, or asbestos.',
  ),
  awarenessAndEducation(
    'Awareness & education',
    'Workshops, talks, or community engagement on eco practices.',
  ),
  other(
    'Other',
    "Custom event that doesn't match the categories above.",
  );

  const EcoEventCategory(this.label, this.description);
  final String label;
  final String description;

  /// The camelCase key sent to/received from the API `category` query param.
  String get key => name;
}

enum EventGear {
  trashBags('Trash bags'),
  gloves('Gloves'),
  rakes('Rakes & shovels'),
  wheelbarrow('Wheelbarrow'),
  waterBoots('Rubber boots'),
  safetyVest('Safety vest'),
  firstAid('First aid kit'),
  sunscreen('Sunscreen & water');

  const EventGear(this.label);
  final String label;
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

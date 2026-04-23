import 'package:flutter/foundation.dart';

/// Immutable snapshot of create-event form inputs for dirty detection.
@immutable
class CreateEventFormFields {
  const CreateEventFormFields({
    required this.siteId,
    required this.dateMillis,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.categoryIndex,
    required this.gearNames,
    required this.scaleIndex,
    required this.difficultyIndex,
    required this.title,
    required this.description,
    required this.maxParticipants,
  });

  final String? siteId;
  final int? dateMillis;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int? categoryIndex;
  final List<String> gearNames;
  final int? scaleIndex;
  final int? difficultyIndex;
  final String title;
  final String description;
  final int? maxParticipants;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CreateEventFormFields &&
        other.siteId == siteId &&
        other.dateMillis == dateMillis &&
        other.startHour == startHour &&
        other.startMinute == startMinute &&
        other.endHour == endHour &&
        other.endMinute == endMinute &&
        other.categoryIndex == categoryIndex &&
        other.scaleIndex == scaleIndex &&
        other.difficultyIndex == difficultyIndex &&
        other.title == title &&
        other.description == description &&
        other.maxParticipants == maxParticipants &&
        listEquals(other.gearNames, gearNames);
  }

  @override
  int get hashCode => Object.hash(
        siteId,
        dateMillis,
        startHour,
        startMinute,
        endHour,
        endMinute,
        categoryIndex,
        Object.hashAll(gearNames),
        scaleIndex,
        difficultyIndex,
        title,
        description,
        maxParticipants,
      );
}

/// Initial form fingerprint captured when the sheet opens.
@immutable
class CreateEventFormSnapshot {
  const CreateEventFormSnapshot(this._initial);

  final CreateEventFormFields _initial;

  bool matches(CreateEventFormFields current) => _initial == current;
}

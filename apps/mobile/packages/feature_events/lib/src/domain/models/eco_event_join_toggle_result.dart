/// Outcome of [EventsRepository.toggleJoin].
class EcoEventJoinToggleResult {
  const EcoEventJoinToggleResult({
    required this.changed,
    this.pointsAwarded = 0,
  });

  final bool changed;

  /// Gamification: points granted for joining (server); 0 when leaving or if none.
  final int pointsAwarded;
}

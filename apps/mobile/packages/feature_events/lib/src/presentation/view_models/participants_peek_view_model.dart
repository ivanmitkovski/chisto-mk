import 'package:feature_events/src/application/events_providers.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/event_participant_row.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/participants_section.dart'
    show AttendeePreview, mergeParticipantPreviews;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'participants_peek_view_model.g.dart';

class ParticipantsPeekState {
  const ParticipantsPeekState({
    this.peekLoading = true,
    this.peekFailed = false,
    this.peekPreviews = const <AttendeePreview>[],
  });

  final bool peekLoading;
  final bool peekFailed;
  final List<AttendeePreview> peekPreviews;

  ParticipantsPeekState copyWith({
    bool? peekLoading,
    bool? peekFailed,
    List<AttendeePreview>? peekPreviews,
  }) {
    return ParticipantsPeekState(
      peekLoading: peekLoading ?? this.peekLoading,
      peekFailed: peekFailed ?? this.peekFailed,
      peekPreviews: peekPreviews ?? this.peekPreviews,
    );
  }
}

/// Peek row state for [ParticipantsSection].
@riverpod
class ParticipantsPeekViewModel extends _$ParticipantsPeekViewModel {
  late EventsRepository _repository;
  late EcoEvent _event;

  @override
  ParticipantsPeekState build(EcoEvent event) {
    _event = event;
    _repository = readEventsRepository();
    return const ParticipantsPeekState();
  }

  // ignore: use_setters_to_change_properties, dependency-injection/test override hook, not a public property
  void setRepository(EventsRepository repository) {
    _repository = repository;
  }

  Future<void> loadPeek({required String youLabel}) async {
    state = state.copyWith(peekLoading: true, peekFailed: false);
    try {
      final EventParticipantsPage page = await _repository.fetchParticipants(
        _event.id,
      );
      state = state.copyWith(
        peekPreviews: mergeParticipantPreviews(
          event: _event,
          apiRows: page.items,
          youLabel: youLabel,
        ),
        peekLoading: false,
        peekFailed: false,
      );
    } on Object catch (_) {
      state = state.copyWith(
        peekLoading: false,
        peekFailed: true,
        peekPreviews: const <AttendeePreview>[],
      );
    }
  }
}

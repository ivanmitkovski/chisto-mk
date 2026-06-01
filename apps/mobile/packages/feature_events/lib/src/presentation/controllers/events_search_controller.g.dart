// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventsSearchControllerHash() =>
    r'1cbe217c612a86efb123cb4d7a2e2640d445f16b';

/// Debounced coordinator for ranked `POST /events/search` (via repository refresh).
///
/// Copied from [EventsSearchController].
@ProviderFor(EventsSearchController)
final eventsSearchControllerProvider =
    NotifierProvider<EventsSearchController, EventsSearchState>.internal(
      EventsSearchController.new,
      name: r'eventsSearchControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$eventsSearchControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EventsSearchController = Notifier<EventsSearchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

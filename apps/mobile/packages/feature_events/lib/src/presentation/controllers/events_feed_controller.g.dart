// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventsFeedControllerHash() =>
    r'a6b9fef7bb4ff5a70439f0ee96ed2af76792df32';

/// Owns feed discovery state: debounced ranked search, chip/server params, calendar toggle,
/// and **memoized** derived lists (nearby / my-events client sorts only; text search is server-side).
///
/// Copied from [EventsFeedController].
@ProviderFor(EventsFeedController)
final eventsFeedControllerProvider =
    NotifierProvider<EventsFeedController, EventsFeedState>.internal(
      EventsFeedController.new,
      name: r'eventsFeedControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$eventsFeedControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EventsFeedController = Notifier<EventsFeedState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

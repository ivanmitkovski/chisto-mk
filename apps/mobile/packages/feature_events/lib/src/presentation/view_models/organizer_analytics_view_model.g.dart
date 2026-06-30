// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organizer_analytics_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$organizerAnalyticsViewModelHash() =>
    r'7fe8a47e3bfceccef57f319bd3de3b9fbf95e913';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$OrganizerAnalyticsViewModel
    extends BuildlessAutoDisposeNotifier<OrganizerAnalyticsState> {
  late final String eventId;

  OrganizerAnalyticsState build(String eventId);
}

/// Loads organizer-only analytics for [OrganizerAnalyticsSection].
///
/// Copied from [OrganizerAnalyticsViewModel].
@ProviderFor(OrganizerAnalyticsViewModel)
const organizerAnalyticsViewModelProvider = OrganizerAnalyticsViewModelFamily();

/// Loads organizer-only analytics for [OrganizerAnalyticsSection].
///
/// Copied from [OrganizerAnalyticsViewModel].
class OrganizerAnalyticsViewModelFamily
    extends Family<OrganizerAnalyticsState> {
  /// Loads organizer-only analytics for [OrganizerAnalyticsSection].
  ///
  /// Copied from [OrganizerAnalyticsViewModel].
  const OrganizerAnalyticsViewModelFamily();

  /// Loads organizer-only analytics for [OrganizerAnalyticsSection].
  ///
  /// Copied from [OrganizerAnalyticsViewModel].
  OrganizerAnalyticsViewModelProvider call(String eventId) {
    return OrganizerAnalyticsViewModelProvider(eventId);
  }

  @override
  OrganizerAnalyticsViewModelProvider getProviderOverride(
    covariant OrganizerAnalyticsViewModelProvider provider,
  ) {
    return call(provider.eventId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'organizerAnalyticsViewModelProvider';
}

/// Loads organizer-only analytics for [OrganizerAnalyticsSection].
///
/// Copied from [OrganizerAnalyticsViewModel].
class OrganizerAnalyticsViewModelProvider
    extends
        AutoDisposeNotifierProviderImpl<
          OrganizerAnalyticsViewModel,
          OrganizerAnalyticsState
        > {
  /// Loads organizer-only analytics for [OrganizerAnalyticsSection].
  ///
  /// Copied from [OrganizerAnalyticsViewModel].
  OrganizerAnalyticsViewModelProvider(String eventId)
    : this._internal(
        () => OrganizerAnalyticsViewModel()..eventId = eventId,
        from: organizerAnalyticsViewModelProvider,
        name: r'organizerAnalyticsViewModelProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$organizerAnalyticsViewModelHash,
        dependencies: OrganizerAnalyticsViewModelFamily._dependencies,
        allTransitiveDependencies:
            OrganizerAnalyticsViewModelFamily._allTransitiveDependencies,
        eventId: eventId,
      );

  OrganizerAnalyticsViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.eventId,
  }) : super.internal();

  final String eventId;

  @override
  OrganizerAnalyticsState runNotifierBuild(
    covariant OrganizerAnalyticsViewModel notifier,
  ) {
    return notifier.build(eventId);
  }

  @override
  Override overrideWith(OrganizerAnalyticsViewModel Function() create) {
    return ProviderOverride(
      origin: this,
      override: OrganizerAnalyticsViewModelProvider._internal(
        () => create()..eventId = eventId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        eventId: eventId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    OrganizerAnalyticsViewModel,
    OrganizerAnalyticsState
  >
  createElement() {
    return _OrganizerAnalyticsViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrganizerAnalyticsViewModelProvider &&
        other.eventId == eventId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, eventId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OrganizerAnalyticsViewModelRef
    on AutoDisposeNotifierProviderRef<OrganizerAnalyticsState> {
  /// The parameter `eventId` of this provider.
  String get eventId;
}

class _OrganizerAnalyticsViewModelProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          OrganizerAnalyticsViewModel,
          OrganizerAnalyticsState
        >
    with OrganizerAnalyticsViewModelRef {
  _OrganizerAnalyticsViewModelProviderElement(super.provider);

  @override
  String get eventId => (origin as OrganizerAnalyticsViewModelProvider).eventId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participants_peek_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$participantsPeekViewModelHash() =>
    r'0086a81b1795c04835b4c5748d6ce607f3b5064c';

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

abstract class _$ParticipantsPeekViewModel
    extends BuildlessAutoDisposeNotifier<ParticipantsPeekState> {
  late final EcoEvent event;

  ParticipantsPeekState build(EcoEvent event);
}

/// Peek row state for [ParticipantsSection].
///
/// Copied from [ParticipantsPeekViewModel].
@ProviderFor(ParticipantsPeekViewModel)
const participantsPeekViewModelProvider = ParticipantsPeekViewModelFamily();

/// Peek row state for [ParticipantsSection].
///
/// Copied from [ParticipantsPeekViewModel].
class ParticipantsPeekViewModelFamily extends Family<ParticipantsPeekState> {
  /// Peek row state for [ParticipantsSection].
  ///
  /// Copied from [ParticipantsPeekViewModel].
  const ParticipantsPeekViewModelFamily();

  /// Peek row state for [ParticipantsSection].
  ///
  /// Copied from [ParticipantsPeekViewModel].
  ParticipantsPeekViewModelProvider call(EcoEvent event) {
    return ParticipantsPeekViewModelProvider(event);
  }

  @override
  ParticipantsPeekViewModelProvider getProviderOverride(
    covariant ParticipantsPeekViewModelProvider provider,
  ) {
    return call(provider.event);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'participantsPeekViewModelProvider';
}

/// Peek row state for [ParticipantsSection].
///
/// Copied from [ParticipantsPeekViewModel].
class ParticipantsPeekViewModelProvider
    extends
        AutoDisposeNotifierProviderImpl<
          ParticipantsPeekViewModel,
          ParticipantsPeekState
        > {
  /// Peek row state for [ParticipantsSection].
  ///
  /// Copied from [ParticipantsPeekViewModel].
  ParticipantsPeekViewModelProvider(EcoEvent event)
    : this._internal(
        () => ParticipantsPeekViewModel()..event = event,
        from: participantsPeekViewModelProvider,
        name: r'participantsPeekViewModelProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$participantsPeekViewModelHash,
        dependencies: ParticipantsPeekViewModelFamily._dependencies,
        allTransitiveDependencies:
            ParticipantsPeekViewModelFamily._allTransitiveDependencies,
        event: event,
      );

  ParticipantsPeekViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.event,
  }) : super.internal();

  final EcoEvent event;

  @override
  ParticipantsPeekState runNotifierBuild(
    covariant ParticipantsPeekViewModel notifier,
  ) {
    return notifier.build(event);
  }

  @override
  Override overrideWith(ParticipantsPeekViewModel Function() create) {
    return ProviderOverride(
      origin: this,
      override: ParticipantsPeekViewModelProvider._internal(
        () => create()..event = event,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        event: event,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    ParticipantsPeekViewModel,
    ParticipantsPeekState
  >
  createElement() {
    return _ParticipantsPeekViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ParticipantsPeekViewModelProvider && other.event == event;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, event.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ParticipantsPeekViewModelRef
    on AutoDisposeNotifierProviderRef<ParticipantsPeekState> {
  /// The parameter `event` of this provider.
  EcoEvent get event;
}

class _ParticipantsPeekViewModelProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          ParticipantsPeekViewModel,
          ParticipantsPeekState
        >
    with ParticipantsPeekViewModelRef {
  _ParticipantsPeekViewModelProviderElement(super.provider);

  @override
  EcoEvent get event => (origin as ParticipantsPeekViewModelProvider).event;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

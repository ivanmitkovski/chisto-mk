// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_picker_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationPickerControllerHash() =>
    r'64e0122d66d34e2cab9aa29d7caecf3ce988839a';

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

abstract class _$LocationPickerController
    extends BuildlessAutoDisposeNotifier<LocationPickerState> {
  late final double? initialLatitude;
  late final double? initialLongitude;

  LocationPickerState build(double? initialLatitude, double? initialLongitude);
}

/// Map-picker state and GPS / reverse-geocode logic (no [BuildContext]).
///
/// Copied from [LocationPickerController].
@ProviderFor(LocationPickerController)
const locationPickerControllerProvider = LocationPickerControllerFamily();

/// Map-picker state and GPS / reverse-geocode logic (no [BuildContext]).
///
/// Copied from [LocationPickerController].
class LocationPickerControllerFamily extends Family<LocationPickerState> {
  /// Map-picker state and GPS / reverse-geocode logic (no [BuildContext]).
  ///
  /// Copied from [LocationPickerController].
  const LocationPickerControllerFamily();

  /// Map-picker state and GPS / reverse-geocode logic (no [BuildContext]).
  ///
  /// Copied from [LocationPickerController].
  LocationPickerControllerProvider call(
    double? initialLatitude,
    double? initialLongitude,
  ) {
    return LocationPickerControllerProvider(initialLatitude, initialLongitude);
  }

  @override
  LocationPickerControllerProvider getProviderOverride(
    covariant LocationPickerControllerProvider provider,
  ) {
    return call(provider.initialLatitude, provider.initialLongitude);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'locationPickerControllerProvider';
}

/// Map-picker state and GPS / reverse-geocode logic (no [BuildContext]).
///
/// Copied from [LocationPickerController].
class LocationPickerControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<
          LocationPickerController,
          LocationPickerState
        > {
  /// Map-picker state and GPS / reverse-geocode logic (no [BuildContext]).
  ///
  /// Copied from [LocationPickerController].
  LocationPickerControllerProvider(
    double? initialLatitude,
    double? initialLongitude,
  ) : this._internal(
        () => LocationPickerController()
          ..initialLatitude = initialLatitude
          ..initialLongitude = initialLongitude,
        from: locationPickerControllerProvider,
        name: r'locationPickerControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$locationPickerControllerHash,
        dependencies: LocationPickerControllerFamily._dependencies,
        allTransitiveDependencies:
            LocationPickerControllerFamily._allTransitiveDependencies,
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      );

  LocationPickerControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialLatitude,
    required this.initialLongitude,
  }) : super.internal();

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  LocationPickerState runNotifierBuild(
    covariant LocationPickerController notifier,
  ) {
    return notifier.build(initialLatitude, initialLongitude);
  }

  @override
  Override overrideWith(LocationPickerController Function() create) {
    return ProviderOverride(
      origin: this,
      override: LocationPickerControllerProvider._internal(
        () => create()
          ..initialLatitude = initialLatitude
          ..initialLongitude = initialLongitude,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    LocationPickerController,
    LocationPickerState
  >
  createElement() {
    return _LocationPickerControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LocationPickerControllerProvider &&
        other.initialLatitude == initialLatitude &&
        other.initialLongitude == initialLongitude;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialLatitude.hashCode);
    hash = _SystemHash.combine(hash, initialLongitude.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LocationPickerControllerRef
    on AutoDisposeNotifierProviderRef<LocationPickerState> {
  /// The parameter `initialLatitude` of this provider.
  double? get initialLatitude;

  /// The parameter `initialLongitude` of this provider.
  double? get initialLongitude;
}

class _LocationPickerControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          LocationPickerController,
          LocationPickerState
        >
    with LocationPickerControllerRef {
  _LocationPickerControllerProviderElement(super.provider);

  @override
  double? get initialLatitude =>
      (origin as LocationPickerControllerProvider).initialLatitude;
  @override
  double? get initialLongitude =>
      (origin as LocationPickerControllerProvider).initialLongitude;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

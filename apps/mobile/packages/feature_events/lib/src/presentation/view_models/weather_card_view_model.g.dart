// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_card_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$weatherCardViewModelHash() =>
    r'aa09cefb949ca6ea0e2ee72b1486d05f4cfcd21b';

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

abstract class _$WeatherCardViewModel
    extends BuildlessAutoDisposeNotifier<WeatherCardState> {
  late final EcoEvent event;

  WeatherCardState build(EcoEvent event);
}

/// Fetches [DayWeather] for [WeatherCard] (Open-Meteo; non-blocking UI).
///
/// Copied from [WeatherCardViewModel].
@ProviderFor(WeatherCardViewModel)
const weatherCardViewModelProvider = WeatherCardViewModelFamily();

/// Fetches [DayWeather] for [WeatherCard] (Open-Meteo; non-blocking UI).
///
/// Copied from [WeatherCardViewModel].
class WeatherCardViewModelFamily extends Family<WeatherCardState> {
  /// Fetches [DayWeather] for [WeatherCard] (Open-Meteo; non-blocking UI).
  ///
  /// Copied from [WeatherCardViewModel].
  const WeatherCardViewModelFamily();

  /// Fetches [DayWeather] for [WeatherCard] (Open-Meteo; non-blocking UI).
  ///
  /// Copied from [WeatherCardViewModel].
  WeatherCardViewModelProvider call(EcoEvent event) {
    return WeatherCardViewModelProvider(event);
  }

  @override
  WeatherCardViewModelProvider getProviderOverride(
    covariant WeatherCardViewModelProvider provider,
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
  String? get name => r'weatherCardViewModelProvider';
}

/// Fetches [DayWeather] for [WeatherCard] (Open-Meteo; non-blocking UI).
///
/// Copied from [WeatherCardViewModel].
class WeatherCardViewModelProvider
    extends
        AutoDisposeNotifierProviderImpl<
          WeatherCardViewModel,
          WeatherCardState
        > {
  /// Fetches [DayWeather] for [WeatherCard] (Open-Meteo; non-blocking UI).
  ///
  /// Copied from [WeatherCardViewModel].
  WeatherCardViewModelProvider(EcoEvent event)
    : this._internal(
        () => WeatherCardViewModel()..event = event,
        from: weatherCardViewModelProvider,
        name: r'weatherCardViewModelProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$weatherCardViewModelHash,
        dependencies: WeatherCardViewModelFamily._dependencies,
        allTransitiveDependencies:
            WeatherCardViewModelFamily._allTransitiveDependencies,
        event: event,
      );

  WeatherCardViewModelProvider._internal(
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
  WeatherCardState runNotifierBuild(covariant WeatherCardViewModel notifier) {
    return notifier.build(event);
  }

  @override
  Override overrideWith(WeatherCardViewModel Function() create) {
    return ProviderOverride(
      origin: this,
      override: WeatherCardViewModelProvider._internal(
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
  AutoDisposeNotifierProviderElement<WeatherCardViewModel, WeatherCardState>
  createElement() {
    return _WeatherCardViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeatherCardViewModelProvider && other.event == event;
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
mixin WeatherCardViewModelRef
    on AutoDisposeNotifierProviderRef<WeatherCardState> {
  /// The parameter `event` of this provider.
  EcoEvent get event;
}

class _WeatherCardViewModelProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          WeatherCardViewModel,
          WeatherCardState
        >
    with WeatherCardViewModelRef {
  _WeatherCardViewModelProviderElement(super.provider);

  @override
  EcoEvent get event => (origin as WeatherCardViewModelProvider).event;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

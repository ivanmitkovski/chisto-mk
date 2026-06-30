// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_report_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$newReportControllerHash() =>
    r'b272967260eaaf040ddd9b3e4a0e19407c6c6ab8';

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

abstract class _$NewReportController
    extends BuildlessAutoDisposeNotifier<NewReportWizardState> {
  late final XFile? initialPhoto;

  NewReportWizardState build(XFile? initialPhoto);
}

/// Wizard controller for [NewReportScreen] (no [BuildContext]).
///
/// Copied from [NewReportController].
@ProviderFor(NewReportController)
const newReportControllerProvider = NewReportControllerFamily();

/// Wizard controller for [NewReportScreen] (no [BuildContext]).
///
/// Copied from [NewReportController].
class NewReportControllerFamily extends Family<NewReportWizardState> {
  /// Wizard controller for [NewReportScreen] (no [BuildContext]).
  ///
  /// Copied from [NewReportController].
  const NewReportControllerFamily();

  /// Wizard controller for [NewReportScreen] (no [BuildContext]).
  ///
  /// Copied from [NewReportController].
  NewReportControllerProvider call(XFile? initialPhoto) {
    return NewReportControllerProvider(initialPhoto);
  }

  @override
  NewReportControllerProvider getProviderOverride(
    covariant NewReportControllerProvider provider,
  ) {
    return call(provider.initialPhoto);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'newReportControllerProvider';
}

/// Wizard controller for [NewReportScreen] (no [BuildContext]).
///
/// Copied from [NewReportController].
class NewReportControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<
          NewReportController,
          NewReportWizardState
        > {
  /// Wizard controller for [NewReportScreen] (no [BuildContext]).
  ///
  /// Copied from [NewReportController].
  NewReportControllerProvider(XFile? initialPhoto)
    : this._internal(
        () => NewReportController()..initialPhoto = initialPhoto,
        from: newReportControllerProvider,
        name: r'newReportControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$newReportControllerHash,
        dependencies: NewReportControllerFamily._dependencies,
        allTransitiveDependencies:
            NewReportControllerFamily._allTransitiveDependencies,
        initialPhoto: initialPhoto,
      );

  NewReportControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialPhoto,
  }) : super.internal();

  final XFile? initialPhoto;

  @override
  NewReportWizardState runNotifierBuild(
    covariant NewReportController notifier,
  ) {
    return notifier.build(initialPhoto);
  }

  @override
  Override overrideWith(NewReportController Function() create) {
    return ProviderOverride(
      origin: this,
      override: NewReportControllerProvider._internal(
        () => create()..initialPhoto = initialPhoto,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialPhoto: initialPhoto,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<NewReportController, NewReportWizardState>
  createElement() {
    return _NewReportControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NewReportControllerProvider &&
        other.initialPhoto == initialPhoto;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialPhoto.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NewReportControllerRef
    on AutoDisposeNotifierProviderRef<NewReportWizardState> {
  /// The parameter `initialPhoto` of this provider.
  XFile? get initialPhoto;
}

class _NewReportControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          NewReportController,
          NewReportWizardState
        >
    with NewReportControllerRef {
  _NewReportControllerProviderElement(super.provider);

  @override
  XFile? get initialPhoto =>
      (origin as NewReportControllerProvider).initialPhoto;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';
import 'package:flutter/foundation.dart';

class CheckInRepositoryRegistry {
  const CheckInRepositoryRegistry._();

  static CheckInRepository? _testOverride;

  @visibleForTesting
  static void setTestOverride(CheckInRepository? repository) {
    _testOverride = repository;
  }

  static CheckInRepository get instance =>
      _testOverride ?? AppBootstrap.instance.checkInRepository;
}

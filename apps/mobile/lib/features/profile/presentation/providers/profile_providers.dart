import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';

/// Bridges [ServiceLocator] repositories into Riverpod (same pattern as home
/// [repository_providers.dart]).
final profileRepositoryProvider = Provider<ProfileRepository>((Ref ref) {
  return ServiceLocator.instance.profileRepository;
});

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return ServiceLocator.instance.authRepository;
});

final reportsApiRepositoryProvider = Provider<ReportsApiRepository>((Ref ref) {
  return ServiceLocator.instance.reportsApiRepository;
});

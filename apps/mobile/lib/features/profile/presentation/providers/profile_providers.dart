import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';

export 'package:chisto_mobile/core/providers/app_providers.dart'
    show authRepositoryProvider;

/// Bridges [AppBootstrap] repositories into Riverpod (same pattern as home
/// [repository_providers.dart]).
final profileRepositoryProvider = Provider<ProfileRepository>((Ref ref) {
  return AppBootstrap.instance.profileRepository;
});

final reportsApiRepositoryProvider = Provider<ReportsApiRepository>((Ref ref) {
  return AppBootstrap.instance.reportsApiRepository;
});

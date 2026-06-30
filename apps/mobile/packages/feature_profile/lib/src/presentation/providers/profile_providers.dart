import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_profile/src/domain/repositories/profile_repository.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chisto_infrastructure/core/providers/app_providers.dart'
    show authRepositoryProvider;

/// Bridges [AppBootstrap] repositories into Riverpod (same pattern as home
/// [repository_providers.dart]).
final profileRepositoryProvider = Provider<ProfileRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).profileRepository;
});

final reportsApiRepositoryProvider = Provider<ReportsApiRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).reportsApiRepository;
});

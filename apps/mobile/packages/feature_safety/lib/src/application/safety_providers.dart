import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_safety/src/data/ugc_moderation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ugcModerationRepositoryProvider = Provider<UgcModerationRepository>((
  Ref ref,
) {
  return UgcModerationRepository(client: ref.watch(apiClientProvider));
});

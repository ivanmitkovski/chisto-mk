import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_auth/src/data/eula_acceptance_store.dart';
import 'package:feature_auth/src/domain/repositories/auth_repository.dart';
import 'package:feature_auth/src/presentation/widgets/community_guidelines_acceptance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows community-guidelines acceptance when needed; signs out on decline.
Future<bool> ensureCommunityGuidelinesAccepted(
  BuildContext context,
  WidgetRef ref,
) async {
  // Use [readRoot] so awaits can outlive the calling widget (e.g. session
  // redirect unmounts [HomeShellBootstrap] while this flow is in flight).
  final String? userId = readRoot(authStateProvider).userId;
  if (userId == null || userId.isEmpty) {
    return false;
  }

  final AuthRepository auth = readRoot(authRepositoryProvider);
  final EulaAcceptanceStore store = EulaAcceptanceStore(
    readRoot(preferencesProvider),
  );
  if (await store.hasAcceptedForUser(userId)) {
    return true;
  }

  if (auth.requiresTermsAcceptance == false) {
    await store.syncFromServer(userId: userId, requiresTermsAcceptance: false);
    return true;
  }

  if (auth.requiresTermsAcceptance == null) {
    try {
      final bool requires = await auth.refreshTermsConsentFromServer();
      if (!requires) {
        return true;
      }
    } on Object {
      // Fall through to dialog when profile fetch fails.
    }
  }

  if (!context.mounted) {
    return false;
  }

  final bool accepted = await showCommunityGuidelinesAcceptanceDialog(
    context,
    ref: ref,
    userId: userId,
  );
  if (accepted) {
    return true;
  }

  await auth.signOut();
  if (!context.mounted) {
    return false;
  }
  AppNavigation.goSignInAndClearStack();
  return false;
}

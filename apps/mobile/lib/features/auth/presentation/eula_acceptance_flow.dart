import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/features/auth/data/eula_acceptance_store.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/auth/presentation/widgets/community_guidelines_acceptance_dialog.dart';

/// Shows community-guidelines acceptance when needed; signs out on decline.
Future<bool> ensureCommunityGuidelinesAccepted(BuildContext context) async {
  final String? userId = AppBootstrap.instance.authState.userId;
  if (userId == null || userId.isEmpty) {
    return false;
  }

  final EulaAcceptanceStore store =
      EulaAcceptanceStore(AppBootstrap.instance.preferences);
  if (await store.hasAcceptedForUser(userId)) {
    return true;
  }

  final AuthRepository auth = AppBootstrap.instance.authRepository;
  if (auth.requiresTermsAcceptance == false) {
    await store.syncFromServer(
      userId: userId,
      requiresTermsAcceptance: false,
    );
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
    userId: userId,
  );
  if (accepted) {
    return true;
  }

  await AppBootstrap.instance.authRepository.signOut();
  if (!context.mounted) {
    return false;
  }
  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
    AppRoutes.signIn,
    (Route<dynamic> route) => false,
  );
  return false;
}

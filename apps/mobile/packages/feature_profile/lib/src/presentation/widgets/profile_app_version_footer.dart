import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/presentation/providers/profile_app_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Subtle app version label below profile settings (non-interactive).
class ProfileAppVersionFooter extends ConsumerWidget {
  const ProfileAppVersionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String> versionAsync = ref.watch(
      profileAppVersionProvider,
    );

    return versionAsync.when(
      data: (String version) {
        if (version.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        final String label = context.l10n.profileAppVersion(version);
        return Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl,
            bottom: AppSpacing.xs,
          ),
          child: Semantics(
            label: label,
            child: ExcludeSemantics(
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypographySurfaces.homeMutedCaption(
                    Theme.of(context).textTheme,
                  ).copyWith(fontSize: 12, letterSpacing: 0.15),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/molecules/app_inline_banner.dart';
import 'package:flutter/material.dart';

class FeedStaleBanner extends StatelessWidget {
  const FeedStaleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: AppInlineBanner(
        message: context.l10n.feedRefreshStaleSnack,
        tone: AppInlineBannerTone.warning,
      ),
    );
  }
}

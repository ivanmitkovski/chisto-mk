import 'dart:async';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Thin banner when the device has no usable data connection (scrolls with feed).
class FeedOfflineBannerHost extends StatefulWidget {
  const FeedOfflineBannerHost({super.key});

  @override
  State<FeedOfflineBannerHost> createState() => _FeedOfflineBannerHostState();
}

class _FeedOfflineBannerHostState extends State<FeedOfflineBannerHost> {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  List<ConnectivityResult> _results = <ConnectivityResult>[];

  static bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return false;
    }
    return results.any(
      (ConnectivityResult r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(
      Connectivity().checkConnectivity().then((List<ConnectivityResult> v) {
        if (mounted) {
          setState(() => _results = v);
        }
      }),
    );
    _subscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> v) {
        if (mounted) {
          setState(() => _results = v);
        }
      },
    );
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline(_results)) {
      return const SizedBox.shrink();
    }
    final double topInset = MediaQuery.paddingOf(context).top;
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.l10n.feedOfflineBanner,
      child: Material(
        color: AppColors.primaryDark.withValues(alpha: 0.06),
        child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          topInset + AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.wifi_off_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.feedOfflineBanner,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

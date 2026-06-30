import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/network/connectivity_gate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:design_system/design_system.dart';
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

  @override
  void initState() {
    super.initState();
    unawaited(
      ConnectivityGate.check().then((List<ConnectivityResult> v) {
        if (mounted) {
          setState(() => _results = v);
        }
      }),
    );
    _subscription = ConnectivityGate.watch().listen((
      List<ConnectivityResult> v,
    ) {
      if (mounted) {
        setState(() => _results = v);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ConnectivityGate.isOnline(_results)) {
      return const SizedBox.shrink();
    }
    final double topInset = MediaQuery.paddingOf(context).top;
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.l10n.connectionOfflineBanner,
      child: Material(
        color: AppColors.error.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            topInset + AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.connectionOfflineBanner,
                  style: AppTypographySurfaces.homeMutedCaption(
                    Theme.of(context).textTheme,
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

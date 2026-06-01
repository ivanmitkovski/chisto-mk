import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/app_error_view.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/screens/pollution_site_detail_screen.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [GoRouter] `extra` when opening site detail from the feed with a hydrated card.
class SiteDetailPreviewExtra {
  const SiteDetailPreviewExtra(this.site);

  final PollutionSite site;
}

/// Loads [PollutionSite] by id then shows [PollutionSiteDetailScreen].
class SiteDetailRouteScreen extends ConsumerStatefulWidget {
  const SiteDetailRouteScreen({
    super.key,
    required this.siteId,
    this.previewSite,
    this.initialAction,
    this.initialHighlight,
    this.initialTabIndex = 0,
  });

  final String siteId;
  final PollutionSite? previewSite;
  final String? initialAction;
  final NotificationInboxHighlight? initialHighlight;
  final int initialTabIndex;

  @override
  ConsumerState<SiteDetailRouteScreen> createState() =>
      _SiteDetailRouteScreenState();
}

class _SiteDetailRouteScreenState extends ConsumerState<SiteDetailRouteScreen> {
  Future<PollutionSite?>? _future;
  PollutionSite? _preview;

  @override
  void initState() {
    super.initState();
    final PollutionSite? p = widget.previewSite;
    _preview = p != null && p.id == widget.siteId ? p : null;
    if (_preview == null) {
      _future = ref.read(sitesRepositoryProvider).getSiteById(widget.siteId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_preview != null) {
      return PollutionSiteDetailScreen(
        site: _preview!,
        skipInitialRefresh: true,
        initialTabIndex: widget.initialTabIndex,
        initialAction: widget.initialAction,
        initialHighlight: widget.initialHighlight,
      );
    }
    return FutureBuilder<PollutionSite?>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<PollutionSite?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: AppLoadingIndicator()));
        }
        if (snapshot.hasError) {
          final Object err = snapshot.error!;
          final AppError appError = err is AppError
              ? err
              : AppError.unknown(cause: err);
          return Scaffold(
            body: AppErrorView(
              error: appError,
              onRetry: () {
                setState(() {
                  _future = ref
                      .read(sitesRepositoryProvider)
                      .getSiteById(widget.siteId);
                });
              },
            ),
          );
        }
        final PollutionSite? site = snapshot.data;
        if (site == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.l10n.feedSiteNotFoundMessage)),
          );
        }
        return PollutionSiteDetailScreen(
          site: site,
          skipInitialRefresh: true,
          initialTabIndex: widget.initialTabIndex,
          initialAction: widget.initialAction,
          initialHighlight: widget.initialHighlight,
        );
      },
    );
  }
}

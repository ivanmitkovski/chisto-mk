import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/shared/widgets/app_error_view.dart';
import 'package:flutter/material.dart';

/// [GoRouter] `extra` when opening site detail from the feed with a hydrated card.
class SiteDetailPreviewExtra {
  const SiteDetailPreviewExtra(this.site);

  final PollutionSite site;
}

/// Loads [PollutionSite] by id then shows [PollutionSiteDetailScreen].
class SiteDetailRouteScreen extends StatefulWidget {
  const SiteDetailRouteScreen({
    super.key,
    required this.siteId,
    this.previewSite,
  });

  final String siteId;
  final PollutionSite? previewSite;

  @override
  State<SiteDetailRouteScreen> createState() => _SiteDetailRouteScreenState();
}

class _SiteDetailRouteScreenState extends State<SiteDetailRouteScreen> {
  late Future<PollutionSite?> _future;
  PollutionSite? _preview;

  @override
  void initState() {
    super.initState();
    final PollutionSite? p = widget.previewSite;
    _preview = p != null && p.id == widget.siteId ? p : null;
    _future = ServiceLocator.instance.sitesRepository.getSiteById(widget.siteId);
  }

  @override
  Widget build(BuildContext context) {
    if (_preview != null) {
      return PollutionSiteDetailScreen(site: _preview!);
    }
    return FutureBuilder<PollutionSite?>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<PollutionSite?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final Object err = snapshot.error!;
          final AppError appError =
              err is AppError ? err : AppError.unknown(cause: err);
          return Scaffold(
            body: AppErrorView(
              error: appError,
              onRetry: () {
                setState(() {
                  _future = ServiceLocator.instance.sitesRepository
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
            body: const Center(child: Text('Site not found')),
          );
        }
        return PollutionSiteDetailScreen(site: site);
      },
    );
  }
}

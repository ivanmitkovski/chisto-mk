import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/data/map_regions/map_region_catalog.dart';
import 'package:chisto_mobile/features/home/data/map_regions/map_region_names_catalog.dart';
import 'package:chisto_mobile/features/home/data/map_regions/macedonia_map_regions.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_region_downloader.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_region_model.dart';
import 'package:chisto_mobile/features/home/data/offline_regions/offline_region_store.dart';
import 'package:chisto_mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:flutter_map/flutter_map.dart';

class SavedMapAreasScreen extends StatefulWidget {
  const SavedMapAreasScreen({super.key});

  @override
  State<SavedMapAreasScreen> createState() => _SavedMapAreasScreenState();
}

class _SavedMapAreasScreenState extends State<SavedMapAreasScreen> {
  OfflineRegionStore get _offlineStore =>
      ServiceLocator.instance.offlineRegionStore;

  OfflineRegionDownloader? _downloader;
  List<OfflineRegion> _regions = <OfflineRegion>[];
  int _totalBytes = 0;
  bool _loading = true;

  String? _downloadingRegionId;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    assert(
      _offlineStore.isInitialized,
      'OfflineRegionStore must init in ServiceLocator',
    );
    _downloader = OfflineRegionDownloader(
      apiClient: ServiceLocator.instance.apiClient,
      store: _offlineStore,
    );
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _regions = _offlineStore.getRegions();
      _totalBytes = _offlineStore.totalSizeBytes;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _downloader?.cancelDownload();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _startDownload(String regionId, String label) async {
    final LatLngBounds? bounds = MacedoniaMapRegions.boundsFor(regionId);
    if (bounds == null) return;

    final OfflineRegion region = OfflineRegion(
      id: regionId,
      label: label,
      minLat: bounds.south,
      maxLat: bounds.north,
      minLng: bounds.west,
      maxLng: bounds.east,
    );

    await _offlineStore.saveRegion(region);
    setState(() {
      _downloadingRegionId = regionId;
      _progress.value = 0.0;
      _regions = _offlineStore.getRegions();
    });

    try {
      await _downloader!.downloadRegion(region, progress: _progress);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SavedMapAreas] download failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        _downloadingRegionId = null;
        _regions = _offlineStore.getRegions();
        _totalBytes = _offlineStore.totalSizeBytes;
      });
    }
  }

  Future<void> _deleteRegion(String id) async {
    if (_downloadingRegionId == id) {
      _downloader?.cancelDownload();
    }
    await _offlineStore.deleteRegion(id);
    _refresh();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final Duration ago = DateTime.now().difference(date);
    if (ago.inMinutes < 1) return 'just now';
    if (ago.inHours < 1) return '${ago.inMinutes}m ago';
    if (ago.inDays < 1) return '${ago.inHours}h ago';
    return '${ago.inDays}d ago';
  }

  void _showAddRegionSheet() {
    final String localeName = Localizations.localeOf(context).toString();

    // Build region entries sorted by localized name.
    final List<String> allIds = <String>[
      ...mapRootRegionIds,
      ...mapSkopjeMunicipalityIds.where(
        (String id) => id != MacedoniaMapRegions.skopjeMetroId,
      ),
    ];
    final Set<String> savedIds =
        _regions.map((OfflineRegion r) => r.id).toSet();

    final List<MapEntry<String, String>> entries = allIds
        .map((String id) {
          final String name =
              mapRegionNameForLocale(id: id, localeName: localeName) ?? id;
          return MapEntry<String, String>(id, name);
        })
        .where((MapEntry<String, String> e) => !savedIds.contains(e.key))
        .toList()
      ..sort((MapEntry<String, String> a, MapEntry<String, String> b) =>
          a.value.compareTo(b.value));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext ctx, ScrollController scrollController) {
            return Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    context.l10n.savedMapAreasTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: entries.length,
                    itemBuilder: (BuildContext context, int index) {
                      final MapEntry<String, String> entry = entries[index];
                      final bool isSkopjeSub =
                          MacedoniaMapRegions.isSkopjeMunicipalityId(entry.key);
                      return ListTile(
                        contentPadding: EdgeInsets.only(
                          left: isSkopjeSub
                              ? AppSpacing.xl
                              : AppSpacing.md,
                          right: AppSpacing.md,
                        ),
                        leading: Icon(
                          Icons.map_outlined,
                          color: AppColors.primary,
                          size: AppSpacing.iconLg,
                        ),
                        title: Text(entry.value),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _startDownload(entry.key, entry.value);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double storageFraction = _totalBytes / OfflineRegionStore.storageCap;
    final bool nearCap = storageFraction > 0.8;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.savedMapAreasTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _downloadingRegionId != null ? null : _showAddRegionSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppRefreshIndicator(
              onRefresh: () async => _refresh(),
              child: _regions.isEmpty
                  ? ListView(
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.cloud_download_outlined,
                                    size: 64,
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    context.l10n.savedMapAreasPlaceholder,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        Expanded(
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.xs),
                            itemCount: _regions.length,
                            itemBuilder: (BuildContext context, int index) {
                              final OfflineRegion region = _regions[index];
                              final bool isDownloading =
                                  _downloadingRegionId == region.id;
                              return _RegionTile(
                                region: region,
                                isDownloading: isDownloading,
                                progress: isDownloading ? _progress : null,
                                formatBytes: _formatBytes,
                                formatDate: _formatDate,
                                onDelete: () => _deleteRegion(region.id),
                                onRefresh: () =>
                                    _startDownload(region.id, region.label),
                              );
                            },
                          ),
                        ),
                        _StorageFooter(
                          totalBytes: _totalBytes,
                          storageCap: OfflineRegionStore.storageCap,
                          nearCap: nearCap,
                          formatBytes: _formatBytes,
                        ),
                      ],
                    ),
            ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.isDownloading,
    required this.progress,
    required this.formatBytes,
    required this.formatDate,
    required this.onDelete,
    required this.onRefresh,
  });

  final OfflineRegion region;
  final bool isDownloading;
  final ValueNotifier<double>? progress;
  final String Function(int) formatBytes;
  final String Function(DateTime?) formatDate;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<String>(region.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.accentDanger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.map,
                    color: region.downloadProgress >= 1.0
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: AppSpacing.iconLg,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      region.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (!isDownloading)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: onRefresh,
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  _InfoChip(
                    icon: Icons.storage_outlined,
                    label: formatBytes(region.sizeBytes),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _InfoChip(
                    icon: Icons.grid_on,
                    label: '${region.tileCount} tiles',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: '${region.siteCount} sites',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Last updated: ${formatDate(region.lastRefreshed)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              if (isDownloading && progress != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                ValueListenableBuilder<double>(
                  valueListenable: progress!,
                  builder: (BuildContext context, double value, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: AppColors.inputFill,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${(value * 100).toStringAsFixed(0)}%',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _StorageFooter extends StatelessWidget {
  const _StorageFooter({
    required this.totalBytes,
    required this.storageCap,
    required this.nearCap,
    required this.formatBytes,
  });

  final int totalBytes;
  final int storageCap;
  final bool nearCap;
  final String Function(int) formatBytes;

  @override
  Widget build(BuildContext context) {
    final double fraction = (totalBytes / storageCap).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        border: Border(
          top: BorderSide(color: AppColors.inputBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Storage used',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  '${formatBytes(totalBytes)} / ${formatBytes(storageCap)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: nearCap
                            ? AppColors.accentWarning
                            : AppColors.textSecondary,
                        fontWeight:
                            nearCap ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 4,
                backgroundColor: AppColors.inputFill,
                valueColor: AlwaysStoppedAnimation<Color>(
                  nearCap ? AppColors.accentWarning : AppColors.primary,
                ),
              ),
            ),
            if (nearCap) ...<Widget>[
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppColors.accentWarning,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Approaching storage limit. Oldest regions will be auto-removed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accentWarningDark,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

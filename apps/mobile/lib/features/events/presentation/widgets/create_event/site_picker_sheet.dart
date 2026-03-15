import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';

class SitePickerSheet extends StatefulWidget {
  const SitePickerSheet({
    super.key,
    required this.allSites,
    required this.selectedSiteId,
    required this.onSelect,
    required this.onClose,
  });

  final List<EventSiteSummary> allSites;
  final String? selectedSiteId;
  final ValueChanged<EventSiteSummary> onSelect;
  final VoidCallback onClose;

  @override
  State<SitePickerSheet> createState() => _SitePickerSheetState();
}

class _SitePickerSheetState extends State<SitePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<EventSiteSummary> get _filteredSites {
    if (_query.isEmpty) return widget.allSites;
    final String q = _query.toLowerCase();
    return widget.allSites
        .where((EventSiteSummary s) =>
            s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<EventSiteSummary> filtered = _filteredSites;

    return ReportSheetScaffold(
      title: 'Choose site',
      subtitle: 'Anchor this event to one cleanup location.',
      trailing: ReportCircleIconButton(
        icon: CupertinoIcons.xmark,
        semanticLabel: 'Close',
        onTap: widget.onClose,
      ),
      maxHeightFactor: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CupertinoSearchTextField(
            controller: _searchController,
            placeholder: 'Search by name or description',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            placeholderStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.radius10,
              vertical: AppSpacing.xs + AppSpacing.xxs / 2,
            ),
            backgroundColor: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onChanged: (String value) => setState(() => _query = value),
            onSuffixTap: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                children: <Widget>[
                  Icon(
                    CupertinoIcons.search,
                    size: 32,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No sites match "$_query"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (BuildContext context, int index) {
                  final EventSiteSummary site = filtered[index];
                  final bool isActive = site.id == widget.selectedSiteId;
                  return ReportActionTile(
                    icon: CupertinoIcons.location_solid,
                    title: site.title,
                    subtitle:
                        '${site.distanceKm.toStringAsFixed(1)} km away · ${site.description}',
                    tone: isActive
                        ? ReportSurfaceTone.accent
                        : ReportSurfaceTone.neutral,
                    trailing: Icon(
                      isActive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 22,
                      color: isActive
                          ? AppColors.primaryDark
                          : AppColors.divider,
                    ),
                    onTap: () => widget.onSelect(site),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

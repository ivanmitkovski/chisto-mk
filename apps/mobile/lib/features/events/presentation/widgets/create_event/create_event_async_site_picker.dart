import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/site_picker_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';

/// Result of loading pollution sites for the create-event picker.
class CreateEventSitesLoadResult {
  const CreateEventSitesLoadResult({
    required this.sites,
    this.usedOfflineFallback = false,
    this.networkError = false,
  });

  final List<EventSiteSummary> sites;
  final bool usedOfflineFallback;
  final bool networkError;
}

/// Opens immediately with a loading state, then shows [SitePickerSheet].
class CreateEventAsyncSitePicker extends StatefulWidget {
  const CreateEventAsyncSitePicker({
    super.key,
    required this.load,
    required this.selectedSiteId,
    required this.initialShowMapTab,
    required this.onSelect,
    required this.onClose,
  });

  final Future<CreateEventSitesLoadResult> Function() load;
  final String? selectedSiteId;
  final bool initialShowMapTab;
  final ValueChanged<EventSiteSummary> onSelect;
  final VoidCallback onClose;

  @override
  State<CreateEventAsyncSitePicker> createState() =>
      _CreateEventAsyncSitePickerState();
}

class _CreateEventAsyncSitePickerState extends State<CreateEventAsyncSitePicker> {
  bool _loading = true;
  CreateEventSitesLoadResult? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    final CreateEventSitesLoadResult loaded = await widget.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _result = loaded;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _result == null) {
      return ReportSheetScaffold(
        title: context.l10n.eventsSitePickerTitle,
        subtitle: context.l10n.eventsSitePickerSubtitle,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: context.l10n.semanticsClose,
          onTap: widget.onClose,
        ),
        maxHeightFactor: 0.45,
        addBottomInset: false,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CupertinoActivityIndicator(radius: 14),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.createEventSitePickerLoading,
                  textAlign: TextAlign.center,
                  style: AppTypography.eventsBodyMuted(Theme.of(context).textTheme),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final CreateEventSitesLoadResult r = _result!;
    return SitePickerSheet(
      allSites: r.sites,
      selectedSiteId: widget.selectedSiteId,
      initialShowMapTab: widget.initialShowMapTab,
      onSelect: widget.onSelect,
      onClose: widget.onClose,
      topBanners: <Widget>[
        if (r.networkError) ...<Widget>[
          ReportInfoBanner(
            title: context.l10n.createEventSitePickerLoadFailedTitle,
            message: context.l10n.createEventSitePickerLoadFailedMessage,
            icon: CupertinoIcons.exclamationmark_circle,
            tone: ReportSurfaceTone.accent,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                unawaited(_fetch());
              },
              child: Text(context.l10n.createEventSitePickerRetry),
            ),
          ),
        ] else if (r.usedOfflineFallback)
          ReportInfoBanner(
            title: context.l10n.createEventSitePickerOfflineTitle,
            message: context.l10n.createEventSitePickerOfflineMessage,
            icon: CupertinoIcons.wifi_slash,
            tone: ReportSurfaceTone.neutral,
          ),
      ],
    );
  }
}

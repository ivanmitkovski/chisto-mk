import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/event_impact_receipt_json.dart';
import 'package:chisto_mobile/features/events/domain/models/event_impact_receipt.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_share_payload.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_diagnostic_log.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/utils/share_popover_origin.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Full-screen impact receipt (server-backed counts + signed media).
class EventImpactReceiptScreen extends StatefulWidget {
  const EventImpactReceiptScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventImpactReceiptScreen> createState() => _EventImpactReceiptScreenState();
}

class _EventImpactReceiptScreenState extends State<EventImpactReceiptScreen> {
  bool _loading = true;
  EventImpactReceipt? _receipt;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ApiResponse res = await ServiceLocator.instance.apiClient.get(
        '/events/${widget.eventId}/impact-receipt',
      );
      final Map<String, dynamic>? json = res.json;
      if (json == null) {
        throw AppError(
          code: 'HTTP_ERROR',
          message: 'Invalid response',
          retryable: false,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _receipt = eventImpactReceiptFromJson(json);
        _loading = false;
        _error = null;
      });
    } on AppError catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e;
        _loading = false;
        _receipt = null;
      });
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppError(
          code: 'HTTP_ERROR',
          message: 'Invalid response',
          retryable: true,
        );
        _loading = false;
        _receipt = null;
      });
    }
  }

  String _completenessLabel(AppLocalizations l10n, EventImpactReceiptCompleteness c) {
    switch (c) {
      case EventImpactReceiptCompleteness.inProgress:
        return l10n.eventsImpactReceiptCompletenessInProgress;
      case EventImpactReceiptCompleteness.full:
        return l10n.eventsImpactReceiptCompletenessFull;
      case EventImpactReceiptCompleteness.partialMissingAfter:
        return l10n.eventsImpactReceiptCompletenessPartialAfter;
      case EventImpactReceiptCompleteness.partialMissingEvidence:
        return l10n.eventsImpactReceiptCompletenessPartialEvidence;
      case EventImpactReceiptCompleteness.partialMissingAfterAndEvidence:
        return l10n.eventsImpactReceiptCompletenessPartialBoth;
    }
  }

  Future<void> _share(EventImpactReceipt receipt) async {
    final AppLocalizations l10n = context.l10n;
    final String base = AppConfig.shareBaseUrlFromEnvironment;
    final String text = buildImpactReceiptSharePlainText(l10n, receipt, base);
    final Uri? uri = eventShareHttpsUri(base, receipt.eventId);
    logEventsDiagnostic('impact_receipt.share_tapped');
    if (uri != null) {
      await Share.shareUri(uri, sharePositionOrigin: sharePopoverOrigin(context));
    } else {
      await Share.share(
        text,
        subject: receipt.title,
        sharePositionOrigin: sharePopoverOrigin(context),
      );
    }
  }

  Future<void> _copyLink(EventImpactReceipt receipt) async {
    final String url = eventSharePageUrl(AppConfig.shareBaseUrlFromEnvironment, receipt.eventId);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) {
      return;
    }
    AppSnack.show(
      context,
      message: context.l10n.eventsImpactReceiptLinkCopied,
      type: AppSnackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final EventImpactReceipt? r = _receipt;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
        titleTextStyle: AppTypography.eventsScreenTitle(textTheme),
        title: Text(l10n.eventsImpactReceiptScreenTitle),
        actions: <Widget>[
          if (r != null) ...<Widget>[
            IconButton(
              tooltip: l10n.eventsImpactReceiptCopyLink,
              color: AppColors.textPrimary,
              icon: const Icon(CupertinoIcons.link),
              onPressed: () => unawaited(_copyLink(r)),
            ),
            IconButton(
              tooltip: l10n.eventsImpactReceiptShare,
              color: AppColors.textPrimary,
              icon: const Icon(CupertinoIcons.share),
              onPressed: () => unawaited(_share(r)),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          localizedAppErrorMessage(l10n, _error!),
                          textAlign: TextAlign.center,
                          style: AppTypography.eventsBodyMuted(textTheme),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          label: l10n.eventsImpactReceiptRetry,
                          onPressed: () => unawaited(_fetch()),
                        ),
                      ],
                    ),
                  ),
                )
              : r == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetch,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          Semantics(
                            label: l10n.eventsImpactReceiptHeroSemantic(r.title),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  r.title,
                                  style: AppTypography.eventsDetailHeadline(textTheme),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  r.siteLabel,
                                  style: AppTypography.eventsBodyMuted(textTheme),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  DateFormat.yMMMd(l10n.localeName)
                                      .add_jm()
                                      .format(r.scheduledAt.toLocal()),
                                  style: AppTypography.eventsCaptionStrong(
                                    textTheme,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
                            ),
                            child: Text(
                              _completenessLabel(l10n, r.completeness),
                              style: AppTypography.eventsGroupedRowPrimary(textTheme),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.eventsImpactReceiptAsOf(
                              DateFormat.yMMMd(l10n.localeName).add_jm().format(r.asOf.toLocal()),
                            ),
                            style: AppTypography.eventsSupportingCaption(textTheme),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _MetricTile(
                                  label: l10n.eventsImpactReceiptMetricCheckIns,
                                  value: r.checkedInCount.toString(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _MetricTile(
                                  label: l10n.eventsImpactReceiptMetricParticipants,
                                  value: r.participantCount.toString(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _MetricTile(
                                  label: l10n.eventsImpactReceiptMetricBags,
                                  value: r.reportedBagsCollected.toString(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.eventsImpactReceiptProofHeading,
                            style: AppTypography.eventsPanelTitle(textTheme),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (r.evidence.isEmpty && r.afterImageUrls.isEmpty)
                            Text(
                              l10n.eventsImpactReceiptNoMediaHint,
                              style: AppTypography.eventsBodyMuted(textTheme),
                            )
                          else ...<Widget>[
                            SizedBox(
                              height: 112,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: <Widget>[
                                  ...r.evidence.map(
                                    (EventImpactReceiptEvidenceItem e) => Padding(
                                      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(AppSpacing.md),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: CachedNetworkImage(
                                            imageUrl: e.imageUrl,
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (BuildContext context, String url, dynamic error) =>
                                                    const ColoredBox(
                                              color: AppColors.inputFill,
                                              child: Icon(CupertinoIcons.photo),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...r.afterImageUrls.map(
                                    (String url) => Padding(
                                      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(AppSpacing.md),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: CachedNetworkImage(
                                            imageUrl: url,
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (BuildContext context, String url, dynamic error) =>
                                                    const ColoredBox(
                                              color: AppColors.inputFill,
                                              child: Icon(CupertinoIcons.photo),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            label: l10n.eventsImpactReceiptShare,
                            onPressed: () {
                              AppHaptics.tap();
                              unawaited(_share(r));
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                AppHaptics.tap();
                                unawaited(_copyLink(r));
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.divider),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusPill),
                                ),
                              ),
                              child: Text(
                                l10n.eventsImpactReceiptCopyLink,
                                style: AppTypography.eventsSecondaryCtaLabel(textTheme)
                                    .copyWith(color: AppColors.primaryDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label $value',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                value,
                style: AppTypography.eventsDisplayStat(textTheme),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.eventsCaptionStrong(
                  textTheme,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

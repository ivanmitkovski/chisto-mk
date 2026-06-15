import 'dart:async';

import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/shared/utils/share_popover_origin.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/feature_events.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/models/take_action_type.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/navigation/feed_shell_route_extras.dart';
import 'package:feature_home/src/presentation/navigation/site_share_result.dart';
import 'package:feature_home/src/presentation/screens/pollution_site_detail_screen.dart';
import 'package:feature_home/src/presentation/utils/site_resolution_helpers.dart';
import 'package:feature_home/src/presentation/widgets/site_card/share_sheet.dart';
import 'package:feature_home/src/presentation/widgets/submit_resolution_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

SiteShareLinkPayload fallbackShareLinkPayloadForSite(
  PollutionSite site, {
  required String channel,
}) {
  final String base = AppConfig.shareBaseUrlFromEnvironment;
  final String url = '$base/sites/${site.id}';
  return SiteShareLinkPayload(
    siteId: site.id,
    cid: '',
    url: url,
    token: '',
    channel: channel,
    expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
  );
}

class TakeActionCoordinator {
  const TakeActionCoordinator._();
  static final Set<String> _inFlightActionKeys = <String>{};

  static Future<TakeActionCoordinatorOutcome> execute(
    BuildContext context,
    WidgetRef ref, {
    required TakeActionType action,
    required PollutionSite site,
    bool isFromSiteDetail = false,
    VoidCallback? onSwitchToCleaningTab,
  }) async {
    final String actionKey = '${site.id}:${action.name}';
    if (_inFlightActionKeys.contains(actionKey)) {
      if (action == TakeActionType.shareSite) {
        return const TakeActionCoordinatorShareOutcome(SiteShareCancelled());
      }
      return const TakeActionCoordinatorFinished();
    }
    _inFlightActionKeys.add(actionKey);
    try {
      switch (action) {
        case TakeActionType.createEcoAction:
          await _handleCreateEcoAction(context, ref, site: site);
          return const TakeActionCoordinatorFinished();
        case TakeActionType.joinAction:
          await _handleJoinAction(
            context,
            site: site,
            isFromSiteDetail: isFromSiteDetail,
            onSwitchToCleaningTab: onSwitchToCleaningTab,
          );
          return const TakeActionCoordinatorFinished();
        case TakeActionType.donateContribute:
          // Donate is intentionally disabled for this release.
          return const TakeActionCoordinatorFinished();
        case TakeActionType.submitResolution:
          await _handleSubmitResolution(context, site: site);
          return const TakeActionCoordinatorFinished();
        case TakeActionType.shareSite:
          final SiteShareResult share = await _handleShareSite(
            context,
            ref,
            site: site,
          );
          return TakeActionCoordinatorShareOutcome(share);
      }
    } finally {
      _inFlightActionKeys.remove(actionKey);
    }
  }

  static Future<void> _handleCreateEcoAction(
    BuildContext context,
    WidgetRef ref, {
    required PollutionSite site,
  }) async {
    try {
      final EcoEvent? created = await EventsNavigation.openCreate(
        context,
        ref: ref,
        auth: ref.read(authStateProvider),
        preselectedSiteId: site.id,
        preselectedSiteName: site.title,
        preselectedSiteImageUrl:
            site.primaryImageUrl != null &&
                site.primaryImageUrl!.trim().isNotEmpty
            ? site.primaryImageUrl!.trim()
            : null,
        preselectedSiteDistanceKm: site.distanceKm,
      );
      if (created != null && context.mounted) {
        await EventsNavigation.openDetail(context, eventId: created.id);
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsOfflineSyncFailed,
          type: AppSnackType.warning,
        );
      }
    }
  }

  static Future<void> _handleSubmitResolution(
    BuildContext context, {
    required PollutionSite site,
  }) async {
    if (hasMyPendingResolution(site)) {
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.submitResolutionAlreadyUnderReviewSnack,
          type: AppSnackType.info,
        );
      }
      return;
    }
    if (!canSubmitSiteResolution(site) && !isPollutionSiteResolved(site)) {
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.submitResolutionNotAvailableSnack,
          type: AppSnackType.warning,
        );
      }
      return;
    }
    if (!context.mounted) return;
    await SubmitResolutionSheet.show(
      context,
      siteId: site.id,
      siteTitle: site.title,
    );
  }

  static Future<void> _handleJoinAction(
    BuildContext context, {
    required PollutionSite site,
    required bool isFromSiteDetail,
    VoidCallback? onSwitchToCleaningTab,
  }) async {
    try {
      if (isFromSiteDetail) {
        if (onSwitchToCleaningTab != null) {
          onSwitchToCleaningTab();
          return;
        }
      }
      if (!context.mounted) {
        return;
      }
      final GoRouter? router = GoRouter.maybeOf(context);
      if (router != null) {
        await router.push(
          '/feed/${site.id}',
          extra: FeedSiteDetailRouteExtra(
            previewSite: site,
            initialTabIndex: 1,
          ),
        );
        return;
      }
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PollutionSiteDetailScreen(
            site: site,
            initialTabIndex: 1,
            skipInitialRefresh: true,
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsOfflineSyncFailed,
          type: AppSnackType.warning,
        );
      }
    }
  }

  static Future<SiteShareLinkPayload> _issueSiteShareLink(
    WidgetRef ref,
    PollutionSite site, {
    required String channel,
  }) async {
    try {
      final SiteShareLinkPayload issued = await ref
          .read(sitesRepositoryProvider)
          .issueSiteShareLink(site.id, channel: channel);
      if (issued.url.trim().isNotEmpty) {
        return issued;
      }
    } catch (_) {
      // Fall through to deterministic non-signed URL in offline/error states.
    }
    return fallbackShareLinkPayloadForSite(site, channel: channel);
  }

  static Future<SiteShareResult> _handleShareSite(
    BuildContext context,
    WidgetRef ref, {
    required PollutionSite site,
  }) async {
    final SiteShareLinkPayload previewIssued = await _issueSiteShareLink(
      ref,
      site,
      channel: 'native',
    );
    if (!context.mounted) {
      return const SiteShareCancelled();
    }
    final String siteUrl = previewIssued.url;
    final ShareAction? action = await AppBottomSheet.show<ShareAction>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext sheetContext) => ShareSheet(
          title: sheetContext.l10n.takeActionShareSiteTitle,
          subtitle: sheetContext.l10n.takeActionShareSiteSubtitle,
          siteTitle: site.title,
          shareUrl: siteUrl,
          siteImageUrl: site.primaryImageUrl,
      ),
    );
    if (action == null || !context.mounted) {
      return const SiteShareCancelled();
    }
    switch (action) {
      case ShareAction.copyLink:
        final SiteShareLinkPayload issued = await _issueSiteShareLink(
          ref,
          site,
          channel: 'link',
        );
        await Clipboard.setData(ClipboardData(text: issued.url));
        if (context.mounted) {
          AppSnack.show(
            context,
            message: context.l10n.takeActionLinkCopied,
            type: AppSnackType.success,
          );
        }
        try {
          final EngagementSnapshot snapshot = await ref
              .read(sitesRepositoryProvider)
              .shareSite(site.id, channel: 'link');
          return SiteShareSuccess(snapshot);
        } catch (_) {
          if (context.mounted) {
            AppSnack.show(
              context,
              message: context.l10n.siteCardShareTrackFailedSnack,
              type: AppSnackType.warning,
            );
          }
          return const SiteShareTrackFailed();
        }
      case ShareAction.sendMessage:
        final SiteShareLinkPayload issued = await _issueSiteShareLink(
          ref,
          site,
          channel: 'native',
        );
        if (!context.mounted) {
          return const SiteShareCancelled();
        }
        final String textWithSignedUrl =
            '${site.title}\n${site.description}\n\n${issued.url}';
        final ShareResult shareResult = await Share.share(
          textWithSignedUrl,
          subject: site.title,
          sharePositionOrigin: sharePopoverOrigin(context),
        );
        if (shareResult.status != ShareResultStatus.success) {
          return const SiteShareCancelled();
        }
        if (!context.mounted) {
          unawaited(
            readRoot(sitesRepositoryProvider).shareSite(
              site.id,
              channel: 'native',
            ),
          );
          return const SiteShareCancelled();
        }
        try {
          final EngagementSnapshot snapshot = await ref
              .read(sitesRepositoryProvider)
              .shareSite(site.id, channel: 'native');
          return SiteShareSuccess(snapshot);
        } catch (_) {
          if (context.mounted) {
            AppSnack.show(
              context,
              message: context.l10n.siteCardShareTrackFailedSnack,
              type: AppSnackType.warning,
            );
          }
          return const SiteShareTrackFailed();
        }
    }
  }
}

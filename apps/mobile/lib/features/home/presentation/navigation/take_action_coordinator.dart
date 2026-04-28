import 'dart:async';

import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/take_action_type.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/site_share_result.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/share_sheet.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/utils/share_popover_origin.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

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
    BuildContext context, {
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
          await _handleCreateEcoAction(context, site: site);
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
        case TakeActionType.shareSite:
          final SiteShareResult share = await _handleShareSite(context, site: site);
          return TakeActionCoordinatorShareOutcome(share);
      }
    } finally {
      _inFlightActionKeys.remove(actionKey);
    }
  }

  static Future<void> _handleCreateEcoAction(
    BuildContext context, {
    required PollutionSite site,
  }) async {
    try {
      AppHaptics.softTransition();
      final EcoEvent? created = await EventsNavigation.openCreate(
        context,
        preselectedSiteId: site.id,
        preselectedSiteName: site.title,
        preselectedSiteImageUrl:
            site.primaryImageUrl != null && site.primaryImageUrl!.trim().isNotEmpty
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

  static Future<void> _handleJoinAction(
    BuildContext context, {
    required PollutionSite site,
    required bool isFromSiteDetail,
    VoidCallback? onSwitchToCleaningTab,
  }) async {
    try {
      AppHaptics.softTransition();
      if (isFromSiteDetail) {
        if (onSwitchToCleaningTab != null) {
          onSwitchToCleaningTab();
          return;
        }
      }
      if (!isFromSiteDetail || onSwitchToCleaningTab == null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => PollutionSiteDetailScreen(
              site: site,
              initialTabIndex: 1,
            ),
          ),
        );
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

  static Future<SiteShareLinkPayload> _issueSiteShareLink(
    PollutionSite site, {
    required String channel,
  }) async {
    try {
      final SiteShareLinkPayload issued = await ServiceLocator
          .instance.sitesRepository
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
    BuildContext context, {
    required PollutionSite site,
  }) async {
    AppHaptics.tap();
    final SiteShareLinkPayload previewIssued =
        await _issueSiteShareLink(site, channel: 'native');
    if (!context.mounted) {
      return const SiteShareCancelled();
    }
    final String siteUrl = previewIssued.url;
    final ShareAction? action = await showModalBottomSheet<ShareAction>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: false,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      barrierColor: AppColors.overlay,
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
        final SiteShareLinkPayload issued =
            await _issueSiteShareLink(site, channel: 'link');
        await Clipboard.setData(ClipboardData(text: issued.url));
        if (context.mounted) {
          AppSnack.show(
            context,
            message: context.l10n.takeActionLinkCopied,
            type: AppSnackType.success,
          );
          AppHaptics.success(context);
        }
        try {
          final EngagementSnapshot snapshot =
              await ServiceLocator.instance.sitesRepository.shareSite(site.id, channel: 'link');
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
        final SiteShareLinkPayload issued =
            await _issueSiteShareLink(site, channel: 'native');
        if (!context.mounted) {
          return const SiteShareCancelled();
        }
        final String textWithSignedUrl = '${site.title}\n${site.description}\n\n${issued.url}';
        await Share.share(
          textWithSignedUrl,
          subject: site.title,
          sharePositionOrigin: sharePopoverOrigin(context),
        );
        if (!context.mounted) {
          return const SiteShareCancelled();
        }
        AppHaptics.success(context);
        try {
          final EngagementSnapshot snapshot =
              await ServiceLocator.instance.sitesRepository.shareSite(site.id, channel: 'native');
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

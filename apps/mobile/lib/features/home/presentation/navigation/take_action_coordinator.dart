import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/models/take_action_type.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/share_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/take_action/donate_sheet.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

class TakeActionCoordinator {
  const TakeActionCoordinator._();

  static Future<void> execute(
    BuildContext context, {
    required TakeActionType action,
    required PollutionSite site,
    VoidCallback? onShareCountChanged,
    bool isFromSiteDetail = false,
    VoidCallback? onSwitchToCleaningTab,
  }) async {
    switch (action) {
      case TakeActionType.createEcoAction:
        await _handleCreateEcoAction(context, site: site);
        break;
      case TakeActionType.joinAction:
        await _handleJoinAction(
          context,
          site: site,
          isFromSiteDetail: isFromSiteDetail,
          onSwitchToCleaningTab: onSwitchToCleaningTab,
        );
        break;
      case TakeActionType.donateContribute:
        await _handleDonate(context, site: site);
        break;
      case TakeActionType.shareSite:
        await _handleShareSite(
          context,
          site: site,
          onShareCountChanged: onShareCountChanged,
        );
        break;
    }
  }

  static Future<void> _handleCreateEcoAction(
    BuildContext context, {
    required PollutionSite site,
  }) async {
    AppHaptics.softTransition();
    final EcoEvent? created = await EventsNavigation.openCreate(
      context,
      preselectedSiteId: site.id,
      preselectedSiteName: site.title,
      preselectedSiteImageUrl: 'assets/images/references/onboarding_reference.png',
      preselectedSiteDistanceKm: site.distanceKm,
    );
    if (created != null && context.mounted) {
      await EventsNavigation.openDetail(context, eventId: created.id);
    }
  }

  static Future<void> _handleJoinAction(
    BuildContext context, {
    required PollutionSite site,
    required bool isFromSiteDetail,
    VoidCallback? onSwitchToCleaningTab,
  }) async {
    AppHaptics.softTransition();
    if (isFromSiteDetail && onSwitchToCleaningTab != null) {
      onSwitchToCleaningTab();
    } else if (!isFromSiteDetail) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PollutionSiteDetailScreen(
            site: site,
            initialTabIndex: 1,
          ),
        ),
      );
    }
  }

  static Future<void> _handleDonate(
    BuildContext context, {
    required PollutionSite site,
  }) async {
    final DonateOption? option = await DonateSheet.show(context, siteTitle: site.title);
    if (option == null || !context.mounted) return;
    await _launchDonateUrl(context);
  }

  static Future<void> _launchDonateUrl(BuildContext context) async {
    const String url = 'https://chisto.mk/donate';
    final bool ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnack.show(
        context,
        message: 'Could not open donation page',
        type: AppSnackType.warning,
      );
    }
  }

  static Future<void> _handleShareSite(
    BuildContext context, {
    required PollutionSite site,
    VoidCallback? onShareCountChanged,
  }) async {
    AppHaptics.tap();
    final ShareAction? action = await showModalBottomSheet<ShareAction>(
      context: context,
      isScrollControlled: false,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      barrierColor: AppColors.overlay,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) => ShareSheet(
        title: 'Share site',
        subtitle: 'Help others discover and support this site',
      ),
    );
    if (action == null || !context.mounted) return;
    const String baseUrl = 'https://chisto.mk';
    final String siteUrl = '$baseUrl/sites/${site.id}';
    final String text = '${site.title}\n${site.description}\n\n$siteUrl';
    switch (action) {
      case ShareAction.copyLink:
        await Clipboard.setData(ClipboardData(text: siteUrl));
        if (context.mounted) {
          AppSnack.show(context, message: 'Link copied', type: AppSnackType.success);
        }
        onShareCountChanged?.call();
        break;
      case ShareAction.sendMessage:
        await Share.share(text, subject: site.title);
        onShareCountChanged?.call();
        break;
      case ShareAction.shareProfile:
        if (context.mounted) {
          AppSnack.show(
            context,
            message: 'Shared to your profile',
            type: AppSnackType.success,
          );
        }
        onShareCountChanged?.call();
        break;
    }
  }
}

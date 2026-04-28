import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Durations and motion helpers for site comments (sheet + route).
class CommentsMotion {
  const CommentsMotion._();

  static const Duration listInsertScroll = Duration(milliseconds: 240);
  static const Duration composerBannerSwitcher = Duration(milliseconds: 160);
  static const Duration listAnimatedSwitcher = Duration(milliseconds: 180);
  static const Duration tileBusyOpacity = AppMotion.xFast;
  static const Duration likeIconSwitcher = Duration(milliseconds: 180);
  static const Duration replyChevronRotation = Duration(milliseconds: 180);
  static const Duration sendButtonOpacity = Duration(milliseconds: 180);

  static Duration replyChevronRotationDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : replyChevronRotation;

  static Duration tileBusyOpacityDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : tileBusyOpacity;

  static Duration composerBannerSwitcherDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : composerBannerSwitcher;

  static Duration listAnimatedSwitcherDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : listAnimatedSwitcher;

  static Duration likeIconSwitcherDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : likeIconSwitcher;

  static Duration sendButtonOpacityDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : sendButtonOpacity;

  static Duration listInsertScrollDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : listInsertScroll;

  static double tileBusyOpacityValue(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? 1 : 0.7;

  static double sendButtonDisabledOpacity(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? 1 : 0.45;

  static Future<void> scrollListToEnd(
    ScrollController controller, {
    required BuildContext context,
    double extraPixels = 120,
  }) async {
    if (!controller.hasClients || controller.positions.length != 1) {
      return;
    }
    final double target = controller.position.maxScrollExtent + extraPixels;
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpTo(
        target.clamp(
          controller.position.minScrollExtent,
          controller.position.maxScrollExtent + 4000,
        ),
      );
      return;
    }
    await controller.animateTo(
      target,
      duration: listInsertScrollDuration(context),
      curve: Curves.easeOutCubic,
    );
  }
}

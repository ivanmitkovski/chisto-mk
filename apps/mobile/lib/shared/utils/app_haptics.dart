// Haptic sequences use [BuildContext] only inside [Future.delayed] after
// `_stillOk` / mounted checks; async-gap lint is intentionally suppressed here.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central haptics for Chisto mobile. Prefer these over raw [HapticFeedback].
///
/// **Reduce motion:** Pass [BuildContext] into methods that accept it so haptics
/// respect `MediaQuery.disableAnimationsOf` (system accessibility).
///
/// **Affordance matrix (iOS-style):**
/// | User action | Typical API |
/// |-------------|-------------|
/// | Tab / segment / chip change | [tap] |
/// | Light confirmation, small toggle | [light] |
/// | Standard press, sheet action | [medium] |
/// | Destructive confirm, strong alert | [strong] or [error] |
/// | Completed flow (save, join, sent) | [success] |
/// | Validation / caution | [warning] |
/// | Navigate into detail / fullscreen row | [softTransition] |
/// | Sheet dismissed by swipe | [sheetDismiss] |
class AppHaptics {
  const AppHaptics._();

  static const Duration _kDelay50 = Duration(milliseconds: 50);
  static const Duration _kDelay85 = Duration(milliseconds: 85);
  static const Duration _kDelay95 = Duration(milliseconds: 95);

  /// When [context] is non-null and reduce motion / disable animations is on,
  /// haptics are skipped (aligned with system accessibility).
  static bool _allowed([BuildContext? context]) {
    if (context == null) return true;
    return !MediaQuery.disableAnimationsOf(context);
  }

  static bool _stillOk(BuildContext? context) {
    if (context == null) return true;
    return context.mounted && _allowed(context);
  }

  static void tap([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.selectionClick();
  }

  static void light([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.lightImpact();
  }

  static void medium([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.mediumImpact();
  }

  static void strong([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.heavyImpact();
  }

  /// Soft transition into a focused screen (e.g. detail, DM, fullscreen). Max premium feel.
  /// Three-step signature: crisp snap → soft land → subtle settle. ~70ms total.
  static void softTransition([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.selectionClick();
    Future<void>.delayed(const Duration(milliseconds: 26), () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
    Future<void>.delayed(const Duration(milliseconds: 68), () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Geo-fence / boundary limit — Instagram disappearing-messages style: soft double-tap.
  /// Fire once when user crosses into the limit (no repeat). Light → light, ~45ms.
  static void boundaryLimitPulse([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 45), () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// First contact with the geofence — strong "wall hit" so the user knows immediately.
  static void boundaryReached([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!_stillOk(context)) return;
      HapticFeedback.selectionClick();
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!_stillOk(context)) return;
      HapticFeedback.mediumImpact();
    });
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Pin moved back inside the allowed area — soft "you're good" landing.
  static void reenteredBounds([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 40), () {
      if (!_stillOk(context)) return;
      HapticFeedback.selectionClick();
    });
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Location confirmed — Apple-style success: one clear medium then soft resolve.
  static void locationConfirmed([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.mediumImpact();
    Future<void>.delayed(_kDelay50, () {
      if (!_stillOk(context)) return;
      HapticFeedback.selectionClick();
    });
    Future<void>.delayed(_kDelay95, () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Confirm rejected (e.g. pin out of bounds) — Apple-style warning: double tap, no heavy.
  static void locationRejected([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.mediumImpact();
    Future<void>.delayed(_kDelay85, () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Snap-back or settle — soft landing after motion.
  static void settle([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.selectionClick();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// GPS / current location found — Apple-style: light then crisp confirm.
  static void gpsFound([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 45), () {
      if (!_stillOk(context)) return;
      HapticFeedback.selectionClick();
    });
  }

  /// GPS failed or permission denied — Apple-style: one clear medium, restrained.
  static void gpsFailed([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.mediumImpact();
  }

  /// Generic success (e.g. form submitted, action completed).
  static void success([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (context != null && !context.mounted) return;
      if (!_allowed(context)) return;
      HapticFeedback.selectionClick();
    });
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (context != null && !context.mounted) return;
      if (!_allowed(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Generic warning (e.g. validation, caution).
  static void warning([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (context != null && !context.mounted) return;
      if (!_allowed(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Generic error (e.g. network failure, invalid action).
  static void error([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (context != null && !context.mounted) return;
      if (!_allowed(context)) return;
      HapticFeedback.mediumImpact();
    });
  }

  /// Cluster expanding into individual markers — medium snap then crisp click.
  static void clusterExpand([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 40), () {
      if (!_stillOk(context)) return;
      HapticFeedback.selectionClick();
    });
  }

  /// Map pin selected — selection click then soft land.
  static void pinSelect([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.selectionClick();
    Future<void>.delayed(const Duration(milliseconds: 30), () {
      if (!_stillOk(context)) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Map pin deselected — single light for minimal presence.
  static void pinDeselect([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.lightImpact();
  }

  /// Bottom sheet dismissed via swipe — light land then crisp click.
  static void sheetDismiss([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 35), () {
      if (!_stillOk(context)) return;
      HapticFeedback.selectionClick();
    });
  }

  /// Long-press on map — hint for future actions, single selection click.
  static void mapLongPress([BuildContext? context]) {
    if (!_allowed(context)) return;
    HapticFeedback.selectionClick();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static void softTransition() {
    HapticFeedback.selectionClick();
    Future<void>.delayed(const Duration(milliseconds: 26), () {
      HapticFeedback.lightImpact();
    });
    Future<void>.delayed(const Duration(milliseconds: 68), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Geo-fence / boundary limit — Instagram disappearing-messages style: soft double-tap.
  /// Fire once when user crosses into the limit (no repeat). Light → light, ~45ms.
  static void boundaryLimitPulse() {
    HapticFeedback.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 45), () {
      HapticFeedback.lightImpact();
    });
  }

  /// First contact with the geofence — strong "wall hit" so the user knows immediately.
  static void boundaryReached() {
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      HapticFeedback.selectionClick();
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      HapticFeedback.mediumImpact();
    });
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Pin moved back inside the allowed area — soft "you're good" landing.
  static void reenteredBounds() {
    HapticFeedback.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 40), () {
      HapticFeedback.selectionClick();
    });
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Location confirmed — Apple-style success: one clear medium then soft resolve.
  static void locationConfirmed() {
    HapticFeedback.mediumImpact();
    Future<void>.delayed(_kDelay50, () {
      HapticFeedback.selectionClick();
    });
    Future<void>.delayed(_kDelay95, () {
      HapticFeedback.lightImpact();
    });
  }

  /// Confirm rejected (e.g. pin out of bounds) — Apple-style warning: double tap, no heavy.
  static void locationRejected() {
    HapticFeedback.mediumImpact();
    Future<void>.delayed(_kDelay85, () {
      HapticFeedback.lightImpact();
    });
  }

  /// Snap-back or settle — soft landing after motion.
  static void settle() {
    HapticFeedback.selectionClick();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      HapticFeedback.lightImpact();
    });
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.lightImpact();
    });
  }

  /// GPS / current location found — Apple-style: light then crisp confirm.
  static void gpsFound() {
    HapticFeedback.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 45), () {
      HapticFeedback.selectionClick();
    });
  }

  /// GPS failed or permission denied — Apple-style: one clear medium, restrained.
  static void gpsFailed() {
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
  static void clusterExpand() {
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 40), () {
      HapticFeedback.selectionClick();
    });
  }

  /// Map pin selected — selection click then soft land.
  static void pinSelect() {
    HapticFeedback.selectionClick();
    Future<void>.delayed(const Duration(milliseconds: 30), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Map pin deselected — single light for minimal presence.
  static void pinDeselect() {
    HapticFeedback.lightImpact();
  }

  /// Bottom sheet dismissed via swipe — light land then crisp click.
  static void sheetDismiss() {
    HapticFeedback.lightImpact();
    Future<void>.delayed(const Duration(milliseconds: 35), () {
      HapticFeedback.selectionClick();
    });
  }

  /// Long-press on map — hint for future actions, single selection click.
  static void mapLongPress() {
    HapticFeedback.selectionClick();
  }
}

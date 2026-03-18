/// Single source of truth for splash and initial-route behaviour.
///
/// Layout constants keep logo size and alignment consistent across screens.
/// Timing constants remove magic numbers and make the flow testable and tunable.
class SplashConstants {
  SplashConstants._();

  // --- Layout (splash_logo, static logo, initial route if it shows logo) ---

  /// Fraction of screen width used for logo (responsive, balanced across devices).
  static const double logoFractionOfScreenWidth = 0.42;

  /// Clamp logo width so it stays readable on small phones and not oversized on tablets.
  static const double logoMinWidth = 120.0;
  static const double logoMaxWidth = 260.0;

  /// Logo aspect ratio (height / width) from Lottie composition.
  static const double logoAspectRatio = 231 / 200;

  /// Fallback fixed size when no layout context (e.g. tests). Use [logoFractionOfScreenWidth] in production.
  static const double logoWidth = 200.0;
  static const double logoHeight = 231.0;

  /// Inner size for Lottie. FittedBox scales this to cover the display size.
  static const double lottieInnerWidth = 200;
  static const double lottieInnerHeight = 231;

  /// Top padding on initial-route when showing logo (for vertical alignment with splash).
  static const double initialRouteTopPadding = 48;

  // --- Timing ---

  /// Switch from Lottie to static logo at this progress (0..1).
  /// Chosen to be before the Lottie opacity fade-out (~49–59%) so we never show end effects.
  static const double lottieProgressCutoff = 0.48;

  /// Max time to wait on splash before navigating (fallback if Lottie never loads or completes).
  static const Duration splashMaxDuration = Duration(seconds: 4);

  /// Fade duration when transitioning from splash to initial route (Apple-like smooth handoff).
  static const Duration splashToInitialTransitionDuration =
      Duration(milliseconds: 280);

  /// Max time to wait for session restore on the initial route before still navigating.
  static const Duration initialRouteSessionTimeout = Duration(seconds: 5);

  /// Minimum time to show the initial route so the fade-in isn’t cut off.
  static const Duration initialRouteMinDisplayTime = Duration(milliseconds: 320);
}

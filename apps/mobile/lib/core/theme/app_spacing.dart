class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 12;
  static const double md = 16;
  /// Horizontal inset for standard outline fields ([AppTheme.light] `inputDecorationTheme`).
  static const double inputPaddingHorizontal = 20;
  /// Vertical inset for standard outline fields ([AppTheme.light] `inputDecorationTheme`).
  static const double inputPaddingVertical = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radius10 = 10;
  static const double radiusMd = 12;
  static const double radius14 = 14;
  static const double radiusLg = 16;
  static const double radius18 = 18;
  static const double radiusXl = 20;
  static const double radius22 = 22;
  static const double radiusSheet = 20;
  static const double radiusCard = 24;
  static const double radiusPill = 28;
  static const double radiusCircle = 999;

  /// Events feed: search row filter + list/calendar toggles ([ViewToggleButton]) — keep
  /// search field height aligned via [AppCupertinoSearchField.toolbarHeight].
  static const double eventsFeedToolbarControlSize = 48;

  /// [EcoEventCard] leading square thumbnail.
  static const double eventsCardThumbnailSize = 72;

  /// In-progress left accent stripe on [EcoEventCard].
  static const double eventsLiveAccentWidth = 3;

  /// Live pulse dot in [_StatusChip].
  static const double eventsPulseDotSize = 6;

  /// Featured [HeroEventCard] media band height (keep in sync with [events_feed_skeleton]).
  static const double eventsHeroCardMediaHeight = 200;

  /// When [MediaQuery.textScaler] exceeds this, stack location + time on two lines.
  static const double eventsHeroCardMetaTwoLineTextScaleThreshold = 1.15;

  static const double sheetHandle = 36;
  static const double sheetHandleHeight = 4;

  /// Primary CTA height in event create/edit modal footers (gear picker, etc.).
  static const double eventsSheetFooterCtaHeight = 52;
  static const double avatarSm = 36;
  static const double avatarMd = 44;
  static const double avatarLg = 64;
}

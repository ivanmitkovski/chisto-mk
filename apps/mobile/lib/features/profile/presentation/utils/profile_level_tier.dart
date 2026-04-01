import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Visual + copy for server tier keys (`gamification-tiers.ts` on API).
IconData profileTierIcon(String tierKey) {
  if (tierKey.startsWith('numeric_')) {
    final n = int.tryParse(tierKey.split('_').last) ?? 1;
    final i = (n - 1).clamp(0, 9);
    return _numericIcons[i];
  }
  if (tierKey == 'prestige_cap') {
    return Icons.workspace_premium_rounded;
  }
  final idx = _prestigeTierIndex(tierKey);
  if (idx != null && idx >= 0 && idx < _prestigeIcons.length) {
    return _prestigeIcons[idx];
  }
  return Icons.emoji_events_outlined;
}

/// Title for a level tier (numeric, prestige, cap) using the same localization as [profileTierTitle].
String profileMilestoneTierTitle(
  BuildContext context, {
  required int level,
  required String levelTierKey,
  required String levelDisplayName,
}) {
  final l10n = AppLocalizations.of(context)!;
  final String key = levelTierKey;
  if (key.startsWith('numeric_')) {
    return l10n.profileLevelLine(level);
  }
  if (key == 'prestige_cap') {
    return l10n.profileTierLegend;
  }
  final int? idx = _prestigeTierIndex(key);
  if (idx != null) {
    final String lang = Localizations.localeOf(context).languageCode;
    final List<String> row = switch (lang) {
      'mk' => _prestigeMk,
      'sq' => _prestigeSq,
      _ => _prestigeEn,
    };
    if (idx < row.length) return row[idx];
  }
  return levelDisplayName;
}

String profileTierTitle(BuildContext context, ProfileUser user) {
  return profileMilestoneTierTitle(
    context,
    level: user.level,
    levelTierKey: user.levelTierKey,
    levelDisplayName: user.levelDisplayName,
  );
}

int? _prestigeTierIndex(String tierKey) {
  final m = RegExp(r'^prestige_(\d+)$').firstMatch(tierKey);
  if (m == null) return null;
  return int.parse(m.group(1)!) - 1;
}

/// Levels 1–10: distinct nature / civic motifs.
const _numericIcons = <IconData>[
  Icons.spa_outlined,
  Icons.eco_outlined,
  Icons.water_drop_outlined,
  Icons.grass_outlined,
  Icons.wb_sunny_outlined,
  Icons.air_outlined,
  Icons.terrain_outlined,
  Icons.hiking_outlined,
  Icons.local_florist_outlined,
  Icons.energy_savings_leaf_outlined,
];

/// Prestige 01–40: unique icons (Material), aligned with tier order on API.
const _prestigeIcons = <IconData>[
  Icons.waves_outlined,
  Icons.landscape_outlined,
  Icons.agriculture_outlined,
  Icons.forest_outlined,
  Icons.cloud_outlined,
  Icons.route_outlined,
  Icons.water_outlined,
  Icons.castle_outlined,
  Icons.campaign_outlined,
  Icons.directions_run_outlined,
  Icons.waterfall_chart_outlined,
  Icons.landslide_outlined,
  Icons.park_outlined,
  Icons.compost_outlined,
  Icons.airline_stops_outlined,
  Icons.wb_twilight_outlined,
  Icons.nights_stay_outlined,
  Icons.explore_outlined,
  Icons.opacity_outlined,
  Icons.emoji_nature_outlined,
  Icons.apartment_outlined,
  Icons.nature_people_outlined,
  Icons.kayaking_outlined,
  Icons.filter_hdr_outlined,
  Icons.record_voice_over_outlined,
  Icons.map_outlined,
  Icons.cleaning_services_outlined,
  Icons.groups_outlined,
  Icons.anchor_outlined,
  Icons.cottage_outlined,
  Icons.park_rounded,
  Icons.science_outlined,
  Icons.pool_outlined,
  Icons.landscape_rounded,
  Icons.location_city_outlined,
  Icons.psychology_outlined,
  Icons.biotech_outlined,
  Icons.recycling_outlined,
  Icons.autorenew_outlined,
  Icons.public_outlined,
];

/// Keep in sync with `PRESTIGE_TIER_NAMES` in `apps/api/src/gamification/gamification-tiers.ts`.
const _prestigeEn = <String>[
  'River Watcher',
  'Valley Keeper',
  'Field Guardian',
  'Grove Sentinel',
  'Sky Steward',
  'Trail Blazer',
  'Spring Voice',
  'Stone Warden',
  'Meadow Herald',
  'Ridge Runner',
  'Creek Protector',
  'Hill Watcher',
  'Canopy Ally',
  'Soil Advocate',
  'Wind Listener',
  'Dawn Patroller',
  'Dusk Ranger',
  'Wild Path Guide',
  'Clear Water Knight',
  'Green Belt Champion',
  'Urban Roots Ally',
  'Park Keeper',
  'Riverbank Defender',
  'Summit Scout',
  'Valley Voice',
  'Eco Cartographer',
  'Cleanup Captain',
  'Circle Steward',
  'Harbor Helper',
  'Plains Protector',
  'Forest Friend',
  'Lake Lookout',
  'Mountain Mate',
  'City Green Lead',
  'Neighborhood Naturalist',
  'Citizen Scientist',
  'Climate Courier',
  'Zero-Waste Warrior',
  'Circular Economy Sage',
  'Planet Partner',
];

const _prestigeMk = <String>[
  'Набљудувач на реките',
  'Чувар на долината',
  'Стражар на полето',
  'Чувар на горето',
  'Небесен старател',
  'Отворач на патеки',
  'Глас на изворот',
  'Камен чувар',
  'Гласник на ливадата',
  'Тркач по сртот',
  'Заштитник на потокот',
  'Набљудувач на ридот',
  'Сојузник на крошната',
  'Застапник на почвата',
  'Слушател на ветрот',
  'Патролец на зората',
  'Ренџер на мракот',
  'Водич на дивиот пат',
  'Витез на чистата вода',
  'Шампион на зелен појас',
  'Сојузник на урбаните корења',
  'Чувар на паркот',
  'Бранител на речниот брег',
  'Извидник на врвот',
  'Глас на долината',
  'Еко картограф',
  'Капитен на чистењето',
  'Старател на кругот',
  'Помошник во пристаништето',
  'Заштитник на рамнината',
  'Пријател на шумата',
  'Чувар на езерото',
  'Другар на планината',
  'Водач на урбаното зеленило',
  'Природен истражувач на соседството',
  'Граѓански научник',
  'Курир за климата',
  'Борец за нула отпад',
  'Мудрец на циркуларната економија',
  'Партнер на планетата',
];

const _prestigeSq = <String>[
  'Vrojtues i lumenjve',
  'Ruajtës i luginës',
  'Kujdestar i fushës',
  'Rojtar i pyllit',
  'Përgjegjës i qiellit',
  'Hapës shtigjesh',
  'Zëri i burimit',
  'Rojtar i gurit',
  'Lajmëtues i livadhit',
  'Vrapues i kreshtës',
  'Mbrojtës i përroit',
  'Vrojtues i kodrës',
  'Aleat i kurorës së pemëve',
  'Avokat i tokës',
  'Dëgjues i erës',
  'Patrullues i agimit',
  'Rojtar i muzgut',
  'Udhërrëfyes i shtegut të egër',
  'Kalorës i ujit të pastër',
  'Kampion i brezit të gjelbër',
  'Aleat i rrënjëve urbane',
  'Ruajtës i parkut',
  'Mbrojtës i bregut të lumit',
  'Skaut i majës',
  'Zëri i luginës',
  'Eko-kartograf',
  'Kapiten pastrimi',
  'Steward i rrethit',
  'Ndihmës në port',
  'Mbrojtës i fushës së hapur',
  'Mik i pyllit',
  'Vrojtues i liqenit',
  'Shok i malit',
  'Udhëheqës i gjelbërit urban',
  'Naturalist i fqinjësisë',
  'Shkencëtar qytetar',
  'Korrier klimatik',
  'Luftëtar zero-mbeturina',
  'Menç i ekonomisë qarkulluese',
  'Partner i planetit',
];

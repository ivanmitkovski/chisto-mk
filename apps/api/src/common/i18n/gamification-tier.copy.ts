/**
 * Localized display titles for gamification levels (mobile profile contract).
 * Keep `NUMERIC_LEVEL_MAX` and prestige count in sync with `gamification-tiers.ts`.
 */
import type { AppLocale } from './app-locale';
import { normalizeAppLocale } from './app-locale';

const NUMERIC_LEVEL_MAX = 10;

export const PRESTIGE_TIER_NAME_COUNT = 40;

const PRESTIGE_TIER_NAMES_EN: readonly string[] = [
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

const PRESTIGE_TIER_NAMES_MK: readonly string[] = [
  'Чувар на реката',
  'Чувар на долината',
  'Страж на полето',
  'Страж на горето',
  'Небесен стјуард',
  'Отворувач на патеки',
  'Глас на пролетта',
  'Камен чувар',
  'Гласник на ливадата',
  'Тркач по сртот',
  'Заштитник на потокот',
  'Чувар на ридот',
  'Сојузник на крошната',
  'Застапник на почвата',
  'Слушател на ветрот',
  'Патролец на зората',
  'Рејнџер на самракот',
  'Водич на дивиот пат',
  'Витез на чистата вода',
  'Шампион на зелениот појас',
  'Сојузник на урбаните корења',
  'Чувар на паркот',
  'Бранител на речниот брег',
  'Извидник на врвот',
  'Глас на долината',
  'Еко картограф',
  'Капетан на чистењето',
  'Стјуард на кругот',
  'Помошник во пристаништето',
  'Заштитник на рамнината',
  'Пријател на шумата',
  'Чувар на езерото',
  'Другар на планината',
  'Водич на урбаното зеленило',
  'Природонаучник на соседството',
  'Граѓански научник',
  'Климатски курир',
  'Воин за нулта отпад',
  'Мудрец на циркуларната економија',
  'Партнер на планетата',
];

/** Aligned with mobile `profile_level_tier.dart` `_prestigeSq`. */
const PRESTIGE_TIER_NAMES_SQ: readonly string[] = [
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

function prestigeNames(locale: AppLocale): readonly string[] {
  switch (locale) {
    case 'sq':
      return PRESTIGE_TIER_NAMES_SQ;
    case 'mk':
      return PRESTIGE_TIER_NAMES_MK;
    default:
      return PRESTIGE_TIER_NAMES_EN;
  }
}

/**
 * Human-readable level title for API responses (`levelDisplayName`).
 */
export function resolveLevelDisplayTitle(level: number, locale: string): string {
  const loc = normalizeAppLocale(locale);
  if (level <= 0) {
    return loc === 'mk' ? 'Ниво 1' : loc === 'sq' ? 'Niveli 1' : 'Level 1';
  }
  if (level <= NUMERIC_LEVEL_MAX) {
    return loc === 'mk' ? `Ниво ${level}` : loc === 'sq' ? `Niveli ${level}` : `Level ${level}`;
  }
  const idx = level - NUMERIC_LEVEL_MAX - 1;
  const names = prestigeNames(loc);
  if (idx >= 0 && idx < PRESTIGE_TIER_NAME_COUNT) {
    return names[idx]!;
  }
  return loc === 'mk' ? 'Легенда на Чисто' : loc === 'sq' ? 'Legjenda e Chisto' : 'Chisto Legend';
}

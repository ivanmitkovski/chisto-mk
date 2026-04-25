/**
 * Localized display titles for gamification levels (mobile profile contract).
 * Keep `NUMERIC_LEVEL_MAX` and prestige count in sync with `gamification-tiers.ts`.
 */
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

function isMacedonianLocale(locale: string): boolean {
  const s = locale.replace(/_/g, '-').trim().toLowerCase();
  return s === 'mk' || s.startsWith('mk-');
}

/**
 * Human-readable level title for API responses (`levelDisplayName`).
 */
export function resolveLevelDisplayTitle(level: number, locale: string): string {
  const mk = isMacedonianLocale(locale);
  if (level <= 0) {
    return mk ? 'Ниво 1' : 'Level 1';
  }
  if (level <= NUMERIC_LEVEL_MAX) {
    return mk ? `Ниво ${level}` : `Level ${level}`;
  }
  const idx = level - NUMERIC_LEVEL_MAX - 1;
  if (idx >= 0 && idx < PRESTIGE_TIER_NAME_COUNT) {
    return mk ? PRESTIGE_TIER_NAMES_MK[idx]! : PRESTIGE_TIER_NAMES_EN[idx]!;
  }
  return mk ? 'Легенда на Чисто' : 'Chisto Legend';
}

import type { EmailLocale } from '../types/email.types';

type LabelMap = Record<string, { en: string; mk: string }>;

function genericHumanize(raw: string): string {
  const trimmed = raw.trim();
  if (!trimmed) return '';
  return trimmed
    .replace(/[-_]+/g, ' ')
    .replace(/\s+/g, ' ')
    .split(' ')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

function fromMap(locale: EmailLocale, map: LabelMap, key: string): string {
  const normalized = key.trim().toLowerCase();
  const entry = map[normalized];
  if (entry) {
    return locale === 'en' ? entry.en : entry.mk;
  }
  return genericHumanize(key);
}

const REPORT_CATEGORY: LabelMap = {
  illegal_landfill: { en: 'Illegal landfill', mk: 'Незаконска депонија' },
  water_pollution: { en: 'Water pollution', mk: 'Загадување на вода' },
  air_pollution: { en: 'Air pollution', mk: 'Загадување на воздух' },
  industrial_waste: { en: 'Industrial waste', mk: 'Индустриски отпад' },
  other: { en: 'Other', mk: 'Друго' },
};

const UGC_SUBJECT_TYPE: LabelMap = {
  site_comment: { en: 'Site comment', mk: 'Коментар на локалитет' },
  event_chat_message: { en: 'Event chat message', mk: 'Порака во чат на настан' },
  user: { en: 'User profile', mk: 'Кориснички профил' },
  site: { en: 'Site', mk: 'Локалитет' },
  event: { en: 'Event', mk: 'Настан' },
  safety_issue: { en: 'Safety issue', mk: 'Безбедносен проблем' },
};

const UGC_REASON: LabelMap = {
  spam: { en: 'Spam', mk: 'Спам' },
  harassment: { en: 'Harassment', mk: 'Вознемирување' },
  hate: { en: 'Hate speech', mk: 'Омраза' },
  violence: { en: 'Violence', mk: 'Насилство' },
  nudity: { en: 'Nudity', mk: 'Голотија' },
  other: { en: 'Other', mk: 'Друго' },
};

const EVENT_CATEGORY: LabelMap = {
  general_cleanup: { en: 'General cleanup', mk: 'Општо чистење' },
  river_and_lake: { en: 'River and lake', mk: 'Река и езеро' },
  tree_and_green: { en: 'Trees and green spaces', mk: 'Дрвја и зелени површини' },
  recycling_drive: { en: 'Recycling drive', mk: 'Акција за рециклажа' },
  hazardous_removal: { en: 'Hazardous waste removal', mk: 'Отстранување опасен отпад' },
  awareness_and_education: { en: 'Awareness and education', mk: 'Подигнување свест' },
  other: { en: 'Other', mk: 'Друго' },
};

const EVENT_SCALE: LabelMap = {
  small: { en: 'Small', mk: 'Мало' },
  medium: { en: 'Medium', mk: 'Средно' },
  large: { en: 'Large', mk: 'Големо' },
  massive: { en: 'Massive', mk: 'Масовно' },
};

const EVENT_DIFFICULTY: LabelMap = {
  easy: { en: 'Easy', mk: 'Лесно' },
  moderate: { en: 'Moderate', mk: 'Умерено' },
  hard: { en: 'Hard', mk: 'Тешко' },
};

const SEVERITY_LABELS: Record<number, { en: string; mk: string }> = {
  1: { en: 'Low', mk: 'Ниско' },
  2: { en: 'Minor', mk: 'Мало' },
  3: { en: 'Moderate', mk: 'Средно' },
  4: { en: 'High', mk: 'Високо' },
  5: { en: 'Severe', mk: 'Критично' },
};

export function humanizeReportCategory(locale: EmailLocale, category: string | null | undefined): string {
  if (!category?.trim()) return '';
  return fromMap(locale, REPORT_CATEGORY, category);
}

export function humanizeReportSeverity(locale: EmailLocale, severity: number | null | undefined): string {
  if (severity == null || !Number.isFinite(severity)) return '';
  const rounded = Math.round(severity);
  const entry = SEVERITY_LABELS[rounded];
  if (entry) {
    return locale === 'en' ? entry.en : entry.mk;
  }
  return String(severity);
}

export function humanizeUgcSubjectType(locale: EmailLocale, subjectType: string | null | undefined): string {
  if (!subjectType?.trim()) return '';
  return fromMap(locale, UGC_SUBJECT_TYPE, subjectType);
}

export function humanizeUgcReason(locale: EmailLocale, reason: string | null | undefined): string {
  if (!reason?.trim()) return '';
  return fromMap(locale, UGC_REASON, reason);
}

export function humanizeEventCategory(locale: EmailLocale, category: string | null | undefined): string {
  if (!category?.trim()) return '';
  return fromMap(locale, EVENT_CATEGORY, category);
}

export function humanizeEventScale(locale: EmailLocale, scale: string | null | undefined): string {
  if (!scale?.trim()) return '';
  return fromMap(locale, EVENT_SCALE, scale);
}

export function humanizeEventDifficulty(locale: EmailLocale, difficulty: string | null | undefined): string {
  if (!difficulty?.trim()) return '';
  return fromMap(locale, EVENT_DIFFICULTY, difficulty);
}

export function formatLocationLabel(
  locale: EmailLocale,
  opts: { address?: string | null; latitude?: number | null; longitude?: number | null },
): string {
  const address = opts.address?.trim();
  if (address) return address;
  const lat = opts.latitude;
  const lng = opts.longitude;
  if (lat != null && lng != null && Number.isFinite(lat) && Number.isFinite(lng)) {
    return `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
  }
  return locale === 'en' ? 'Not specified' : 'Не е наведено';
}

export function truncatePreview(text: string | null | undefined, maxLen = 140): string {
  const trimmed = text?.trim() ?? '';
  if (!trimmed) return '';
  if (trimmed.length <= maxLen) return trimmed;
  return `${trimmed.slice(0, maxLen - 1).trimEnd()}…`;
}

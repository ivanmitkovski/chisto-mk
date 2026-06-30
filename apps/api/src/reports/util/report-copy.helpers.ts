import { stripCategoryLabelPrefix } from './report-category-narrative';
import type { ReportSubmitLocale } from './report-locale.util';

/** Fallback for reports created before reportNumber column (e.g. during migration). */
export function getReportNumberFallback(report: { id: string; createdAt: Date }): string {
  const shortId = report.id.slice(0, 4).toUpperCase();
  const yearSuffix = report.createdAt.getFullYear().toString().slice(-2);
  return `R-${yearSuffix}-${shortId}`;
}

export function getReportNumber(report: {
  id: string;
  createdAt: Date;
  reportNumber?: string | null;
}): string {
  return report.reportNumber ?? getReportNumberFallback(report);
}

export function formatLatLngLabel(latitude: number, longitude: number): string {
  return `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
}

/**
 * Location for queues and lists: never duplicate the report narrative when legacy `Site.description`
 * was copied from `Report.description` (pre-address migration); show coordinates instead.
 */
export function listLocationLabel(
  site: { latitude: number; longitude: number; description: string | null; address: string | null },
  reportDescription: string | null,
): string {
  const address = site.address?.trim();
  if (address) return address;
  const legacy = site.description?.trim();
  const narrative = reportDescription?.trim();
  if (legacy && narrative && legacy === narrative) {
    return formatLatLngLabel(site.latitude, site.longitude);
  }
  if (legacy) return legacy;
  return formatLatLngLabel(site.latitude, site.longitude);
}

/** Report narrative for titles; falls back to legacy site.description when report text is empty. */
export function reportNarrativeTitle(
  reportDescription: string | null,
  legacySiteDescription: string | null,
): string {
  const narrative = reportDescription?.trim();
  if (narrative) return narrative;
  const legacy = legacySiteDescription?.trim();
  if (legacy) return legacy;
  return 'Reported site';
}

/** Title / name for moderation and citizen lists (strips mobile "Category: …" prefix). */
export function listReportTitle(
  reportDescription: string | null,
  legacySiteDescription: string | null,
  category: string | null,
): string {
  const raw = reportNarrativeTitle(reportDescription, legacySiteDescription);
  const stripped = stripCategoryLabelPrefix(raw, category);
  if (stripped.length > 0) return stripped;
  if (raw.trim().length > 0) return 'No additional details';
  return raw.trim() || 'Reported site';
}

/** Headline: stored title when present, else legacy derivation (pre-title migration rows). */
export function displayReportTitle(report: {
  title: string;
  description: string | null;
  site: { description: string | null };
  category: string | null;
}): string {
  const trimmed = report.title?.trim();
  if (trimmed) return trimmed;
  return listReportTitle(report.description, report.site.description, report.category);
}

/** Optional narrative body only (no headline); strips category prefix from legacy single-field text. */
export function optionalReportNarrative(
  description: string | null,
  category: string | null,
): string | null {
  if (description == null || description.trim() === '') {
    return null;
  }
  const stripped = stripCategoryLabelPrefix(description, category);
  return stripped.length > 0 ? stripped : null;
}

/** Admin dashboard notification when a citizen submits a report (localized). */
export function adminSubmitNotificationCopy(params: {
  locale: ReportSubmitLocale;
  isNewSite: boolean;
  reportNumber: string;
}): { title: string; message: string; timeLabel: string } {
  const { locale, isNewSite, reportNumber } = params;
  if (locale === 'en') {
    return isNewSite
      ? {
          title: 'New polluted site reported',
          message: `Report ${reportNumber} was submitted at a new location.`,
          timeLabel: 'Just now',
        }
      : {
          title: 'Co-report added to an existing site',
          message: `Report ${reportNumber} was submitted near an existing site.`,
          timeLabel: 'Just now',
        };
  }
  if (locale === 'sq') {
    return isNewSite
      ? {
          title: 'U raportua një vend i ri i ndotur',
          message: `Raporti ${reportNumber} u paraqit në një lokacion të ri.`,
          timeLabel: 'Tani',
        }
      : {
          title: 'U shtua bashkëraportim në një vend ekzistues',
          message: `Raporti ${reportNumber} u paraqit pranë një vendi ekzistues.`,
          timeLabel: 'Tani',
        };
  }
  return isNewSite
    ? {
        title: 'Пријавено е ново загадувачко место',
        message: `Извештај ${reportNumber} е поднесен на нова локација.`,
        timeLabel: 'Штотуку',
      }
    : {
        title: 'Додаден е ко-извештај кон постоечко место',
        message: `Извештај ${reportNumber} е поднесен во близина на постоечко место.`,
        timeLabel: 'Штотуку',
      };
}


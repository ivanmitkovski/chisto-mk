import { EcoEventLifecycleStatus, UserStatus } from '../../prisma-client';
import { projectPublicReporter } from '../../common/projections/public-identity.projection';
import type {
  SitePublicShareEventDto,
  SitePublicShareReporterDto,
} from '../dto/site-public-share-card.dto';

export const SHARE_CARD_MEDIA_CAP = 12;
export const SHARE_CARD_EVENTS_CAP = 5;
export const SHARE_CARD_EVIDENCE_CAP = 12;

export type ShareCardApprovedReportRow = {
  title: string;
  description: string | null;
  mediaUrls: string[];
  category: string | null;
  severity: number | null;
  cleanupEffort: string | null;
  createdAt: Date;
  reporterId: string | null;
  reporter: {
    firstName: string;
    lastName: string;
    avatarObjectKey: string | null;
    status: UserStatus;
  } | null;
};

export function pickPrimaryShareReport(
  hero: ShareCardApprovedReportRow | null,
  reports: ShareCardApprovedReportRow[],
): ShareCardApprovedReportRow | null {
  if (hero != null) return hero;
  return reports[0] ?? null;
}

export function publicShareTitle(
  hero: { title: string } | null,
  reports: { title: string }[],
  description: string | null,
): string {
  const heroTitle = hero?.title?.trim();
  if (heroTitle != null && heroTitle.length > 0) {
    return heroTitle;
  }
  const reportTitle = reports[0]?.title?.trim();
  if (reportTitle != null && reportTitle.length > 0) {
    return reportTitle;
  }
  const desc = description?.trim();
  if (desc != null && desc.length > 0) {
    return desc.length > 120 ? `${desc.slice(0, 117)}…` : desc;
  }
  return 'Pollution site';
}

export function publicShareSiteLabel(site: {
  address: string | null;
  description: string | null;
}): string {
  const address = site.address?.trim();
  if (address != null && address.length > 0) {
    return address;
  }
  const description = site.description?.trim();
  if (description != null && description.length > 0) {
    return description.length > 120 ? `${description.slice(0, 117)}…` : description;
  }
  return 'Site';
}

export function publicShareDescription(
  siteDescription: string | null,
  primary: ShareCardApprovedReportRow | null,
): string | null {
  const fromReport = primary?.description?.trim();
  if (fromReport != null && fromReport.length > 0) {
    return fromReport;
  }
  const fromSite = siteDescription?.trim();
  if (fromSite != null && fromSite.length > 0) {
    return fromSite;
  }
  return null;
}

export function collectShareMediaUrls(
  hero: { mediaUrls: string[] } | null,
  reports: { mediaUrls: string[] }[],
): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  const push = (urls: string[] | undefined) => {
    for (const raw of urls ?? []) {
      const u = typeof raw === 'string' ? raw.trim() : '';
      if (u.length === 0 || seen.has(u)) continue;
      seen.add(u);
      out.push(u);
      if (out.length >= SHARE_CARD_MEDIA_CAP) return;
    }
  };
  push(hero?.mediaUrls);
  for (const r of reports) {
    if (out.length >= SHARE_CARD_MEDIA_CAP) break;
    push(r.mediaUrls);
  }
  return out;
}

export function buildShareReporter(
  primary: ShareCardApprovedReportRow | null,
  avatarByKey: Map<string, string | null>,
): SitePublicShareReporterDto | null {
  if (primary == null) return null;
  const view = projectPublicReporter(primary.reporterId, primary.reporter, undefined, false);
  if (view == null) return null;
  const key = primary.reporter?.avatarObjectKey ?? null;
  return {
    displayLabel: view.displayLabel,
    avatarUrl: key != null ? (avatarByKey.get(key) ?? null) : null,
    isDeleted: view.isDeleted,
    isAnonymous: view.isAnonymous,
  };
}

export function buildShareEvents(
  events: {
    id: string;
    title: string;
    scheduledAt: Date;
    participantCount: number;
    maxParticipants: number | null;
    lifecycleStatus: EcoEventLifecycleStatus;
  }[],
  city: string,
): SitePublicShareEventDto[] {
  return events.map((e) => ({
    id: e.id,
    title: e.title,
    scheduledAt: e.scheduledAt.toISOString(),
    city,
    participantCount: e.participantCount,
    maxParticipants: e.maxParticipants,
    status: e.lifecycleStatus,
  }));
}

/** Deduped evidence URL list from approved resolutions (event after-photos appended by caller). */
export function pushUniqueUrls(
  target: string[],
  seen: Set<string>,
  urls: Iterable<string | null | undefined>,
  cap: number,
): void {
  for (const raw of urls) {
    const u = typeof raw === 'string' ? raw.trim() : '';
    if (u.length === 0 || seen.has(u)) continue;
    seen.add(u);
    target.push(u);
    if (target.length >= cap) return;
  }
}

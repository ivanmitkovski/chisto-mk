import Image from "next/image";
import type { ShareLocale } from "@/i18n/config";
import type { SiteShareCopy } from "@/app/sites/[id]/site-share-strings";
import {
  formatCleanupEffort,
  formatEventSchedule,
  formatReportCategory,
  formatSeverity,
  formatShareDate,
  formatSiteStatus,
  mapsUrl,
} from "@/app/sites/[id]/site-share-strings";
import { ShareHeroGallery } from "./ShareHeroGallery";
import { ShareStatusPill } from "./ShareStatusPill";
import { ShareMetaRows } from "./ShareMetaRows";
import { ShareStatsRow } from "./ShareStatsRow";
import { ShareReporterRow } from "./ShareReporterRow";
import { ShareEventsList } from "./ShareEventsList";
import { ShareEvidenceSection } from "./ShareEvidenceSection";
import { ShareStickyCta } from "./ShareStickyCta";
import type { SiteShareCard } from "./types";

type SiteShareViewProps = {
  card: SiteShareCard;
  locale: ShareLocale;
  t: SiteShareCopy;
  openInAppHref: string;
  getAppHref: string;
  exploreHref: string;
  siteBase: string;
};

export function SiteShareView({
  card,
  locale,
  t,
  openInAppHref,
  getAppHref,
  exploreHref,
  siteBase,
}: SiteShareViewProps) {
  const statusLabel = formatSiteStatus(card.status, locale);
  const explainer = t.statusExplainer[card.status];
  const category = formatReportCategory(card.category, locale);
  const severity = formatSeverity(card.severity, locale);
  const effort = formatCleanupEffort(card.cleanupEffort, locale);
  const locationValue = card.address?.trim() || card.siteLabel;
  const mapHref =
    Number.isFinite(card.latitude) && Number.isFinite(card.longitude)
      ? mapsUrl(card.latitude, card.longitude)
      : undefined;

  const metaRows = [
    category ? { label: t.categoryLabel, value: category } : null,
    severity ? { label: t.severityLabel, value: severity } : null,
    effort ? { label: t.cleanupEffortLabel, value: effort } : null,
    locationValue
      ? {
          label: t.locationLabel,
          value: locationValue,
          href: mapHref,
        }
      : null,
  ].filter((r): r is { label: string; value: string; href?: string } => r != null);

  const reporterName = card.reporter?.isDeleted
    ? t.reporterDeleted
    : card.reporter?.isAnonymous ||
        !card.reporter?.displayLabel?.trim() ||
        card.reporter.displayLabel.trim().toLowerCase() === "anonymous"
      ? t.reporterAnonymous
      : card.reporter.displayLabel.trim();

  return (
    <div className="min-h-dvh bg-[#F4F5F7] text-[#121212]">
      <div className="mx-auto max-w-2xl px-4 pb-36 pt-8 sm:px-6 sm:pt-10">
        <header className="mb-6 flex items-center gap-2">
          <Image
            src="/brand/chisto-mark.svg"
            alt=""
            width={28}
            height={32}
            className="h-7 w-auto"
            unoptimized
          />
          <span className="text-lg font-bold tracking-tight">
            Chisto<span className="brand-logotype font-medium text-primary">.mk</span>
          </span>
        </header>

        <article className="overflow-hidden rounded-[24px] border border-[#E5E7ED]/90 bg-white shadow-[var(--shadow-card)] ring-1 ring-black/[0.04]">
          <div className="p-4 sm:p-6">
            <ShareHeroGallery
              urls={card.mediaUrls}
              alt={card.title}
              emptyLabel={t.noPhotos}
              openPhotoLabel={t.openPhoto}
              closeLabel={t.closeLightbox}
              prevLabel={t.previousPhoto}
              nextLabel={t.nextPhoto}
            />

            <div className="mt-5 flex flex-wrap items-center gap-2">
              <ShareStatusPill status={card.status} label={statusLabel} />
            </div>

            <div className="mt-4">
              <ShareStatsRow
                ariaLabel={t.engagementLabel}
                stats={[
                  { label: t.upvotes, value: card.upvotesCount },
                  { label: t.comments, value: card.commentsCount },
                  { label: t.shares, value: card.sharesCount },
                  { label: t.saves, value: card.savesCount },
                ]}
              />
            </div>

            <h1 className="mt-5 text-2xl font-bold tracking-tight text-[#121212] sm:text-[1.65rem]">
              {card.title}
            </h1>
            {card.description && card.description.trim() !== card.title.trim() ? (
              <p className="mt-3 text-base leading-[1.45] text-[#4C4C4C]">{card.description}</p>
            ) : null}

            <div className="mt-5">
              <ShareMetaRows rows={metaRows} />
            </div>

            {card.reporter || card.reportedAt ? (
              <div className="mt-6 border-t border-[#E5E7ED] pt-5">
                <ShareReporterRow
                  reportedByLabel={t.reportedBy}
                  name={reporterName}
                  dateLabel={formatShareDate(card.reportedAt, locale)}
                  avatarUrl={card.reporter?.avatarUrl ?? null}
                />
              </div>
            ) : null}

            {card.events.length > 0 ? (
              <div className="mt-6 border-t border-[#E5E7ED] pt-5">
                <ShareEventsList
                  title={t.upcomingCleanups}
                  participantsLabel={t.participants}
                  events={card.events}
                  formatSchedule={(iso) => formatEventSchedule(iso, locale)}
                  eventHref={(id) => `${siteBase}/events/${encodeURIComponent(id)}`}
                />
              </div>
            ) : null}

            {card.cleanupEvidenceUrls.length > 0 ? (
              <div className="mt-6 border-t border-[#E5E7ED] pt-5">
                <ShareEvidenceSection
                  title={t.cleanupEvidence}
                  urls={card.cleanupEvidenceUrls}
                  emptyLabel={t.noPhotos}
                  openPhotoLabel={t.openPhoto}
                  closeLabel={t.closeLightbox}
                  prevLabel={t.previousPhoto}
                  nextLabel={t.nextPhoto}
                />
              </div>
            ) : null}

            {explainer ? (
              <div
                className={
                  card.status === "DISPUTED"
                    ? "mt-6 rounded-2xl border border-[#F7D2CF]/90 bg-[#FFF1F0] p-3"
                    : card.status === "IN_PROGRESS" || card.status === "CLEANUP_SCHEDULED"
                      ? "mt-6 rounded-2xl border border-[#FFE1B3]/90 bg-[#FFF6E8] p-3"
                      : "mt-6 rounded-2xl border border-[#D0F0DF]/90 bg-[#EDFFF6] p-3"
                }
                role="note"
              >
                <p className="text-base font-semibold text-[#121212]">{explainer.title}</p>
                <p className="mt-1 text-sm leading-[1.35] text-[#4C4C4C]">
                  {card.status === "CLEANED" && card.cleanupEvidenceUrls.length === 0
                    ? t.cleanedNoEvidenceBody
                    : explainer.body}
                </p>
              </div>
            ) : null}
          </div>
        </article>
      </div>

      <ShareStickyCta
        openInAppHref={openInAppHref}
        openInAppLabel={t.openInApp}
        getAppHref={getAppHref}
        getAppLabel={t.getTheApp}
        exploreHref={exploreHref}
        exploreLabel={t.exploreCta}
      />
    </div>
  );
}

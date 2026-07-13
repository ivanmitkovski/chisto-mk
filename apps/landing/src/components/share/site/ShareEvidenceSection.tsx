"use client";

import { ShareHeroGallery } from "./ShareHeroGallery";

type ShareEvidenceSectionProps = {
  title: string;
  urls: string[];
  emptyLabel: string;
  openPhotoLabel: string;
  closeLabel: string;
  prevLabel: string;
  nextLabel: string;
  unavailableLabel?: string;
};

export function ShareEvidenceSection({
  title,
  urls,
  emptyLabel,
  openPhotoLabel,
  closeLabel,
  prevLabel,
  nextLabel,
  unavailableLabel,
}: ShareEvidenceSectionProps) {
  if (urls.length === 0) return null;
  return (
    <section aria-labelledby="share-evidence-heading">
      <h2 id="share-evidence-heading" className="mb-3 text-base font-semibold text-ink">
        {title}
      </h2>
      <ShareHeroGallery
        urls={urls}
        alt={title}
        emptyLabel={emptyLabel}
        openPhotoLabel={openPhotoLabel}
        closeLabel={closeLabel}
        prevLabel={prevLabel}
        nextLabel={nextLabel}
        {...(unavailableLabel != null ? { unavailableLabel } : {})}
      />
    </section>
  );
}

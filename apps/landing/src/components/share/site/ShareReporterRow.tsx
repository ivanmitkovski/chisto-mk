"use client";

import { useState } from "react";

type ShareReporterRowProps = {
  reportedByLabel: string;
  name: string;
  dateLabel: string;
  avatarUrl: string | null;
};

export function ShareReporterRow({
  reportedByLabel,
  name,
  dateLabel,
  avatarUrl,
}: ShareReporterRowProps) {
  const [avatarFailed, setAvatarFailed] = useState(false);
  const initial = name.trim().charAt(0).toUpperCase() || "?";

  return (
    <div className="flex items-center gap-3">
      <div className="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-full bg-surface-muted text-sm font-semibold text-ink-muted">
        {avatarUrl && !avatarFailed ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={avatarUrl}
            alt=""
            className="h-full w-full object-cover"
            onError={() => setAvatarFailed(true)}
            referrerPolicy="no-referrer"
          />
        ) : (
          <span aria-hidden>{initial}</span>
        )}
      </div>
      <div className="min-w-0">
        <p className="text-xs font-semibold uppercase tracking-wide text-ink-muted">{reportedByLabel}</p>
        <p className="truncate text-base font-semibold text-ink">{name}</p>
        {dateLabel ? <p className="text-sm text-ink-muted">{dateLabel}</p> : null}
      </div>
    </div>
  );
}

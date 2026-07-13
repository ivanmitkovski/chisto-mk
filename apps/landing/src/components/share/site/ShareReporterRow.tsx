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
  return (
    <div className="flex items-center gap-3">
      <div className="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-full bg-[#F0F1F7] text-sm font-semibold text-[#7A7A7A]">
        {avatarUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={avatarUrl} alt="" className="h-full w-full object-cover" />
        ) : (
          <span aria-hidden>{name.trim().charAt(0).toUpperCase() || "?"}</span>
        )}
      </div>
      <div className="min-w-0">
        <p className="text-xs font-semibold uppercase tracking-wide text-[#7A7A7A]">{reportedByLabel}</p>
        <p className="truncate text-base font-semibold text-[#121212]">{name}</p>
        {dateLabel ? <p className="text-sm text-[#7A7A7A]">{dateLabel}</p> : null}
      </div>
    </div>
  );
}

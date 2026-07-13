import { cn } from "@/lib/utils/cn";

const STATUS_STYLES: Record<string, { dot: string; bg: string; text: string }> = {
  VERIFIED: { dot: "bg-primary", bg: "bg-status-mint", text: "text-primary-dark" },
  CLEANUP_SCHEDULED: { dot: "bg-[#3BA3F7]", bg: "bg-[#EDF3FF]", text: "text-[#1D6FA8]" },
  IN_PROGRESS: { dot: "bg-[#F5A623]", bg: "bg-[#FFF8EC]", text: "text-[#D4910C]" },
  CLEANED: { dot: "bg-primary", bg: "bg-status-mint", text: "text-primary-dark" },
  DISPUTED: { dot: "bg-[#E6513D]", bg: "bg-[#FFF0EE]", text: "text-[#E6513D]" },
};

type ShareStatusPillProps = {
  status: string;
  label: string;
  className?: string;
};

export function ShareStatusPill({ status, label, className }: ShareStatusPillProps) {
  const style = STATUS_STYLES[status] ?? {
    dot: "bg-gray-400",
    bg: "bg-surface-muted",
    text: "text-ink-secondary",
  };
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-[11px] font-semibold",
        style.bg,
        style.text,
        className,
      )}
    >
      <span className={cn("h-[7px] w-[7px] shrink-0 rounded-full", style.dot)} aria-hidden />
      {label}
    </span>
  );
}

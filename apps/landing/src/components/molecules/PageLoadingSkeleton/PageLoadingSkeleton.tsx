import { cn } from "@/lib/utils/cn";

export function PageLoadingSkeleton({
  srLabel,
  className,
  lines = 4,
}: {
  srLabel: string;
  className?: string;
  lines?: number;
}) {
  return (
    <div className={cn("animate-pulse space-y-4", className)} aria-busy="true">
      <p className="sr-only">{srLabel}</p>
      {Array.from({ length: lines }, (_, i) => (
        <div
          key={i}
          className={cn(
            "h-4 rounded-lg bg-gray-200/80",
            i === 0 && "h-6 w-2/3",
            i === 1 && "w-full",
            i === 2 && "w-5/6",
            i === 3 && "w-4/6",
          )}
        />
      ))}
    </div>
  );
}

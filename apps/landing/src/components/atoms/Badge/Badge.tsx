import { cn } from "@/lib/utils/cn";

interface BadgeProps {
  children: React.ReactNode;
  className?: string;
  /** Calmer kicker for long-form / about (less “marketing badge”). */
  variant?: "default" | "about";
}

export function Badge({ children, className, variant = "default" }: BadgeProps) {
  return (
    <span
      className={cn(
        variant === "about"
          ? "inline-flex items-center rounded-full bg-gray-100/95 px-3 py-1 text-[0.6875rem] font-semibold uppercase tracking-[0.1em] text-gray-600 ring-1 ring-gray-200/90"
          : "inline-flex items-center rounded-full bg-gradient-to-br from-primary/12 via-primary/8 to-emerald-500/10 px-3 py-1 text-[0.6875rem] font-bold uppercase tracking-[0.22em] text-primary-700 ring-1 ring-primary/20 shadow-sm shadow-primary/5",
        className,
      )}
    >
      {children}
    </span>
  );
}

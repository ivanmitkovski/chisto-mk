import { cn } from "@/lib/utils/cn";

interface SectionProps {
  children: React.ReactNode;
  className?: string;
  id?: string;
  /** default: full section rhythm; tight: slightly less vertical padding */
  spacing?: "default" | "tight";
}

export function Section({ children, className, id, spacing = "default" }: SectionProps) {
  return (
    <section
      id={id}
      className={cn(spacing === "tight" ? "section-y-tight" : "section-y", className)}
    >
      {children}
    </section>
  );
}

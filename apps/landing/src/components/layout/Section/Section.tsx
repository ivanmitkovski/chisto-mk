import { cn } from "@/lib/utils/cn";

interface SectionProps {
  children: React.ReactNode;
  className?: string;
  id?: string;
  /** default: full section rhythm; tight: slightly less vertical padding */
  spacing?: "default" | "tight";
  /** Skip rendering cost until near viewport (below-fold sections). */
  defer?: boolean;
}

export function Section({ children, className, id, spacing = "default", defer = false }: SectionProps) {
  return (
    <section
      id={id}
      className={cn(
        spacing === "tight" ? "section-y-tight" : "section-y",
        defer && "[content-visibility:auto] [contain-intrinsic-size:auto_32rem]",
        className,
      )}
    >
      {children}
    </section>
  );
}

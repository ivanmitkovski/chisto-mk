import { cn } from "@/lib/utils/cn";

type MetaRow = {
  label: string;
  value: string;
  href?: string;
};

type ShareMetaRowsProps = {
  rows: MetaRow[];
};

export function ShareMetaRows({ rows }: ShareMetaRowsProps) {
  if (rows.length === 0) return null;
  return (
    <dl className="space-y-3">
      {rows.map((row) => {
        const valueNode = row.href ? (
          <a
            href={row.href}
            target="_blank"
            rel="noopener noreferrer"
            className="font-semibold text-[#121212] underline-offset-2 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          >
            {row.value}
          </a>
        ) : (
          <span className="font-semibold text-[#121212]">{row.value}</span>
        );
        return (
          <div key={row.label} className="flex gap-3 text-sm leading-snug sm:items-baseline">
            <dt className="w-[7rem] shrink-0 text-sm font-semibold text-[#7A7A7A]">{row.label}</dt>
            <dd className={cn("min-w-0 flex-1 text-base")}>{valueNode}</dd>
          </div>
        );
      })}
    </dl>
  );
}

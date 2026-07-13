type Stat = { label: string; value: number };

type ShareStatsRowProps = {
  stats: Stat[];
  ariaLabel: string;
};

export function ShareStatsRow({ stats, ariaLabel }: ShareStatsRowProps) {
  return (
    <ul className="flex flex-wrap gap-2" aria-label={ariaLabel}>
      {stats.map((stat) => (
        <li
          key={stat.label}
          className="inline-flex items-center gap-1.5 rounded-full bg-[#F0F1F7] px-3 py-1 text-[11px] font-semibold text-[#4C4C4C]"
        >
          <span className="tabular-nums text-[#121212]">{stat.value}</span>
          <span>{stat.label}</span>
        </li>
      ))}
    </ul>
  );
}

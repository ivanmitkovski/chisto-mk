'use client';

import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

type ChartDataItem = {
  dateLabel: string;
  count: number;
};

type ReportsTrendChartInnerProps = {
  data: ChartDataItem[];
  height?: number;
};

export function ReportsTrendChartInner({ data, height = 120 }: ReportsTrendChartInnerProps) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <AreaChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="reportsGradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--color-primary)" stopOpacity={0.4} />
            <stop offset="100%" stopColor="var(--color-green-010)" stopOpacity={0} />
          </linearGradient>
        </defs>
        <XAxis
          dataKey="dateLabel"
          tick={{ fontSize: 11, fill: 'var(--text-secondary)' }}
          tickLine={false}
          axisLine={false}
        />
        <YAxis
          tick={{ fontSize: 11, fill: 'var(--text-secondary)' }}
          tickLine={false}
          axisLine={false}
          allowDecimals={false}
        />
        <Tooltip
          contentStyle={{
            backgroundColor: 'var(--bg-surface)',
            border: '1px solid var(--border-default)',
            borderRadius: 'var(--radius-md)',
          }}
          labelStyle={{ color: 'var(--text-primary)' }}
          formatter={(value) => [value ?? 0, 'Reports']}
        />
        <Area
          type="monotone"
          dataKey="count"
          stroke="var(--color-primary)"
          strokeWidth={2}
          fill="url(#reportsGradient)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

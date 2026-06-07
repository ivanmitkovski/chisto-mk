'use client';

import { Line, LineChart, ResponsiveContainer, YAxis } from 'recharts';
import type { SparklinePoint } from './sparkline';

type SparklineInnerProps = {
  data: SparklinePoint[];
  height?: number;
  ariaLabel: string;
};

export function SparklineInner({ data, height = 36, ariaLabel }: SparklineInnerProps) {
  const chartData = data.map((point) => ({ value: point.v }));

  return (
    <ResponsiveContainer width="100%" height={height} aria-label={ariaLabel}>
      <LineChart data={chartData} margin={{ top: 2, right: 0, left: 0, bottom: 0 }}>
        <YAxis hide domain={['dataMin', 'dataMax']} />
        <Line
          type="monotone"
          dataKey="value"
          stroke="var(--color-primary)"
          strokeWidth={1.5}
          dot={false}
          isAnimationActive={false}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}

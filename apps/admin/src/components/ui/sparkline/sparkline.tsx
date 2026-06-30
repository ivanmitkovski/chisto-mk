'use client';

import dynamic from 'next/dynamic';
import styles from './sparkline.module.css';

export type SparklinePoint = {
  t: number;
  v: number;
};

const SparklineInner = dynamic(
  () => import('./sparkline-inner').then((mod) => ({ default: mod.SparklineInner })),
  {
    ssr: false,
    loading: () => <span className={styles.skeleton} aria-hidden />,
  },
);

export type SparklineProps = {
  data: SparklinePoint[];
  height?: number;
  ariaLabel: string;
};

export function Sparkline({ data, height = 36, ariaLabel }: SparklineProps) {
  if (data.length < 2) {
    return <span className={styles.placeholder} aria-hidden />;
  }

  return (
    <div className={styles.wrap}>
      <SparklineInner data={data} height={height} ariaLabel={ariaLabel} />
      <table className="sr-only">
        <caption>{ariaLabel}</caption>
        <thead>
          <tr>
            <th scope="col">Time</th>
            <th scope="col">Value</th>
          </tr>
        </thead>
        <tbody>
          {data.map((point) => (
            <tr key={point.t}>
              <td>{new Date(point.t).toISOString()}</td>
              <td>{point.v}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

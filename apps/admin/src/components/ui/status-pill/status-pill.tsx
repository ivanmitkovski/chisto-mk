import { Tag } from '../tag';

export function StatusPill({ status }: { status: string }) {
  const normalized = status.toUpperCase();
  const tone =
    normalized.includes('FAIL') || normalized.includes('ERROR') || normalized.includes('DELETED')
      ? 'danger'
      : normalized.includes('OPEN') || normalized.includes('PENDING') || normalized.includes('DEGRADED')
        ? 'warning'
        : normalized.includes('OK') || normalized.includes('ACTIVE') || normalized.includes('APPROVED') || normalized.includes('SUCCESS')
          ? 'success'
          : 'neutral';
  return <Tag tone={tone}>{status.replace(/_/g, ' ')}</Tag>;
}

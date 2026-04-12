import { EcoEventLifecycleStatus } from '../prisma-client';

export function canTransitionLifecycle(
  from: EcoEventLifecycleStatus,
  to: EcoEventLifecycleStatus,
): boolean {
  if (from === to) {
    return true;
  }
  switch (from) {
    case EcoEventLifecycleStatus.UPCOMING:
      return to === EcoEventLifecycleStatus.IN_PROGRESS || to === EcoEventLifecycleStatus.CANCELLED;
    case EcoEventLifecycleStatus.IN_PROGRESS:
      return to === EcoEventLifecycleStatus.COMPLETED || to === EcoEventLifecycleStatus.CANCELLED;
    case EcoEventLifecycleStatus.COMPLETED:
    case EcoEventLifecycleStatus.CANCELLED:
      return false;
    default:
      return false;
  }
}

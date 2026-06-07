import { ImmersiveMapSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function MapLoading() {
  return createDashboardLoadingPage({
    activeItem: 'map',
    contentMode: 'immersive',
    children: <ImmersiveMapSkeleton />,
  });
}

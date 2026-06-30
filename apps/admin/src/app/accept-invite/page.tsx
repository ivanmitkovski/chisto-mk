import { Suspense } from 'react';
import { AcceptInviteFlow } from '@/features/accept-invite';

export default function AcceptInvitePage() {
  return (
    <Suspense fallback={null}>
      <AcceptInviteFlow />
    </Suspense>
  );
}

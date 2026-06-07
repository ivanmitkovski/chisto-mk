'use client';

import { useRouter } from 'next/navigation';
import { useLocale, useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import type { ConflictingEventInfo } from '@/features/events/lib/event-schedule-conflict-client';
import { formatEventAdminDateTime } from '@/features/events/lib/event-admin-datetime';

type DuplicateEventModalProps = {
  open: boolean;
  conflict: ConflictingEventInfo;
  onClose: () => void;
};

export function DuplicateEventModal({ open, conflict, onClose }: DuplicateEventModalProps) {
  const router = useRouter();
  const locale = useLocale();
  const t = useTranslations('events');
  return (
    <Modal
      open={open}
      title={t('scheduleConflict.title')}
      description={t('scheduleConflict.description', {
        title: conflict.title,
        datetime: formatEventAdminDateTime(conflict.scheduledAt, locale),
      })}
      onClose={onClose}
      footer={
        <>
          <Button type="button" variant="outline" onClick={onClose}>
            {t('scheduleConflict.changeTime')}
          </Button>
          <Button type="button" onClick={() => void router.push(`/dashboard/events/${conflict.id}`)}>
            {t('scheduleConflict.openEvent')}
          </Button>
        </>
      }
    />
  );
}

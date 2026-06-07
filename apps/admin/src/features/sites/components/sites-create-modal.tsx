'use client';

import dynamic from 'next/dynamic';
import { useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Input, Modal, useToast } from '@/components/ui';
import { useOptimisticMutation } from '@/features/admin-shell/hooks/use-optimistic-mutation';
import { adminBrowserFetch } from '@/lib/api';
import styles from './sites-create-modal.module.css';

const SitesMapPicker = dynamic(
  () => import('./sites-map-picker').then((m) => ({ default: m.SitesMapPicker })),
  { ssr: false, loading: () => <div className={styles.mapPlaceholder} aria-hidden /> },
);

type SitesCreateModalProps = {
  open: boolean;
  onClose: () => void;
  onCreated: () => void;
};

export function SitesCreateModal({ open, onClose, onCreated }: SitesCreateModalProps) {
  const t = useTranslations('sites');
  const tCommon = useTranslations('common');
  const { showToast, clearToast } = useToast();
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [description, setDescription] = useState('');

  const parsedLat = useMemo(() => {
    const value = Number(latitude);
    return Number.isFinite(value) ? value : null;
  }, [latitude]);

  const parsedLng = useMemo(() => {
    const value = Number(longitude);
    return Number.isFinite(value) ? value : null;
  }, [longitude]);

  const createMutation = useOptimisticMutation({
    mutate: async () => {
      const lat = parsedLat!;
      const lng = parsedLng!;
      return adminBrowserFetch('/sites', {
        method: 'POST',
        body: {
          latitude: lat,
          longitude: lng,
          ...(description.trim() ? { description: description.trim() } : {}),
        },
      });
    },
    successToast: { title: t('create.createdTitle'), message: t('create.createdMessage') },
    errorToast: { title: t('create.failedTitle'), message: t('create.failedMessage') },
    onSuccess: () => {
      reset();
      onCreated();
      onClose();
    },
  });

  function reset() {
    setLatitude('');
    setLongitude('');
    setDescription('');
  }

  function handleClose() {
    if (createMutation.isPending) return;
    reset();
    onClose();
  }

  function handleMapPick(lat: number, lng: number) {
    setLatitude(lat.toFixed(6));
    setLongitude(lng.toFixed(6));
  }

  async function submit() {
    if (parsedLat == null || parsedLat < -90 || parsedLat > 90) {
      showToast({
        tone: 'warning',
        title: t('create.invalidLatitudeTitle'),
        message: t('create.invalidLatitudeMessage'),
      });
      return;
    }
    if (parsedLng == null || parsedLng < -180 || parsedLng > 180) {
      showToast({
        tone: 'warning',
        title: t('create.invalidLongitudeTitle'),
        message: t('create.invalidLongitudeMessage'),
      });
      return;
    }
    clearToast();
    await createMutation.run(null);
  }

  return (
    <Modal
      open={open}
      title={t('create.title')}
      description={t('create.description')}
      onClose={handleClose}
      footer={
        <div className={styles.footer}>
          <Button type="button" variant="outline" onClick={handleClose} disabled={createMutation.isPending}>
            {tCommon('cancel')}
          </Button>
          <Button type="button" onClick={() => void submit()} disabled={createMutation.isPending}>
            {createMutation.isPending ? tCommon('creating') : t('create.createSite')}
          </Button>
        </div>
      }
    >
      <div className={styles.form}>
        <SitesMapPicker latitude={parsedLat} longitude={parsedLng} onPick={handleMapPick} />
        <Input
          label={t('create.latitude')}
          type="number"
          inputMode="decimal"
          step="any"
          value={latitude}
          onChange={(e) => setLatitude(e.target.value)}
        />
        <Input
          label={t('create.longitude')}
          type="number"
          inputMode="decimal"
          step="any"
          value={longitude}
          onChange={(e) => setLongitude(e.target.value)}
        />
        <label className={styles.textareaLabel} htmlFor="site-create-description">
          {t('create.descriptionLabel')}
          <textarea
            id="site-create-description"
            className={styles.textarea}
            rows={3}
            maxLength={500}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder={t('create.descriptionPlaceholder')}
          />
        </label>
      </div>
    </Modal>
  );
}

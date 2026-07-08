'use client';

import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import { Modal } from '@/components/ui/modal';
import { modKeyLabel } from '@/components/ui/rich-text-editor';
import styles from './news-shortcuts-dialog.module.css';

type NewsShortcutsDialogProps = {
  open: boolean;
  onClose: () => void;
};

type ShortcutRow = {
  keys: string;
  label: string;
};

export function NewsShortcutsDialog({ open, onClose }: NewsShortcutsDialogProps) {
  const t = useTranslations('news');
  const mod = useMemo(() => modKeyLabel(), []);

  const sections: { title: string; rows: ShortcutRow[] }[] = useMemo(
    () => [
      {
        title: t('shortcuts.writing'),
        rows: [
          { keys: 'Enter', label: t('shortcuts.enterNewBlock') },
          { keys: `${mod}Enter`, label: t('shortcuts.modEnterNewBlock') },
          { keys: 'Backspace', label: t('shortcuts.backspaceMerge') },
          { keys: `${mod}B`, label: t('shortcuts.modBold') },
          { keys: `${mod}I`, label: t('shortcuts.modItalic') },
          { keys: `${mod}U`, label: t('shortcuts.modUnderline') },
          { keys: `${mod}K`, label: t('shortcuts.modLink') },
        ],
      },
      {
        title: t('shortcuts.blocks'),
        rows: [
          { keys: '/', label: t('shortcuts.slashPalette') },
          { keys: `${mod}/`, label: t('shortcuts.modSlashPalette') },
          { keys: `${mod}Shift+7`, label: t('shortcuts.modOrderedList') },
          { keys: `${mod}Shift+8`, label: t('shortcuts.modBulletList') },
          { keys: `${mod}Shift+B`, label: t('shortcuts.pasteBody') },
        ],
      },
    ],
    [mod, t],
  );

  return (
    <Modal
      open={open}
      title={t('shortcuts.title')}
      description={t('shortcuts.description')}
      onClose={onClose}
    >
      <div className={styles.sections}>
        {sections.map((section) => (
          <section key={section.title} className={styles.section}>
            <h3 className={styles.sectionTitle}>{section.title}</h3>
            <dl className={styles.list}>
              {section.rows.map((row) => (
                <div key={row.keys} className={styles.row}>
                  <dt className={styles.keys}>
                    <kbd>{row.keys}</kbd>
                  </dt>
                  <dd className={styles.label}>{row.label}</dd>
                </div>
              ))}
            </dl>
          </section>
        ))}
      </div>
    </Modal>
  );
}

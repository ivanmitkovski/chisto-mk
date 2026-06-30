'use client';

import { ReactNode } from 'react';
import styles from './news-document-shell.module.css';

type NewsDocumentShellProps = {
  document: ReactNode;
  inspector: ReactNode;
  preview?: ReactNode;
  previewOpen?: boolean;
};

export function NewsDocumentShell({
  document,
  inspector,
  preview,
  previewOpen = false,
}: NewsDocumentShellProps) {
  return (
    <div className={`${styles.shell} ${previewOpen ? styles.shellWithPreview : ''}`}>
      <div className={styles.documentColumn}>
        <div className={styles.documentInner}>{document}</div>
      </div>
      {previewOpen && preview ? <div className={styles.previewColumn}>{preview}</div> : null}
      <aside className={styles.inspectorColumn}>{inspector}</aside>
    </div>
  );
}

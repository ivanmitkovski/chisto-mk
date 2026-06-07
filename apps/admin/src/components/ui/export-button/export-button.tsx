'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';

import { Button, type ButtonProps } from '../button';
import { Icon } from '../icon';

export type ExportButtonProps = Omit<ButtonProps, 'onClick' | 'children' | 'isLoading'> & {
  filename: string;
  getData: () => string | Blob | Promise<string | Blob>;
  label?: string;
  mimeType?: string;
  isLoading?: boolean;
  onExportError?: (error: unknown) => void;
  onExported?: () => void;
};

export function ExportButton({
  filename,
  getData,
  label,
  mimeType = 'text/csv;charset=utf-8',
  onExportError,
  onExported,
  isLoading = false,
  variant = 'outline',
  size = 'sm',
  ...buttonProps
}: ExportButtonProps) {
  const t = useTranslations('ui');
  const resolvedLabel = label ?? t('export');
  const [exporting, setExporting] = useState(false);

  async function handleClick() {
    setExporting(true);
    try {
      const data = await getData();
      const blob = data instanceof Blob ? data : new Blob([data], { type: mimeType });
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement('a');
      anchor.href = url;
      anchor.download = filename;
      anchor.rel = 'noopener';
      anchor.click();
      URL.revokeObjectURL(url);
      onExported?.();
    } catch (error) {
      onExportError?.(error);
    } finally {
      setExporting(false);
    }
  }

  return (
    <Button
      {...buttonProps}
      type="button"
      variant={variant}
      size={size}
      isLoading={isLoading || exporting}
      onClick={() => void handleClick()}
    >
      <Icon name="download" size={14} aria-hidden />
      {resolvedLabel}
    </Button>
  );
}

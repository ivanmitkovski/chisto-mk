'use client';

import { Component, type ReactNode } from 'react';
import { useTranslations } from 'next-intl';
import { SectionState } from '@/components/ui';
import { clientLogger, getErrorReference } from '@/lib/observability';
import { DashboardRefreshButton } from './dashboard-refresh-button';
import styles from './dashboard-error-boundary.module.css';

type Props = {
  children: ReactNode;
  fallback?: ReactNode;
  sectionName?: string;
};

type State = {
  hasError: boolean;
  reference?: string;
};

function DashboardErrorFallback({
  sectionName,
  reference,
}: {
  sectionName?: string;
  reference?: string;
}) {
  const t = useTranslations('dashboard.errorBoundary');
  const tCommon = useTranslations('common');

  const message = sectionName
    ? t('sectionFailed', { sectionName }) +
      (reference ? ` ${tCommon('reference', { id: reference })}` : '')
    : t('sectionFailed', { sectionName: tCommon('unknown') }) +
      (reference ? ` ${tCommon('reference', { id: reference })}` : '');

  return (
    <div className={styles.wrap}>
      <SectionState variant="error" message={message} />
      <DashboardRefreshButton label={t('retry')} variant="ghost" className={styles.retryButton} />
    </div>
  );
}

export class DashboardErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    const reference = getErrorReference(error);
    return reference ? { hasError: true, reference } : { hasError: true };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    const reference = getErrorReference(error);
    clientLogger.error('dashboard_section_error', {
      section: this.props.sectionName,
      message: error.message,
      ...(reference !== undefined ? { requestId: reference } : {}),
      componentStack: errorInfo.componentStack,
    });
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }
      return (
        <DashboardErrorFallback
          {...(this.props.sectionName !== undefined ? { sectionName: this.props.sectionName } : {})}
          {...(this.state.reference !== undefined ? { reference: this.state.reference } : {})}
        />
      );
    }
    return this.props.children;
  }
}

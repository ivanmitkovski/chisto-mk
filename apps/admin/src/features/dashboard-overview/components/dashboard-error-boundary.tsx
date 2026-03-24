'use client';

import { Component, type ReactNode } from 'react';
import { SectionState } from '@/components/ui';
import { DashboardRefreshButton } from './dashboard-refresh-button';
import styles from './dashboard-error-boundary.module.css';

type Props = {
  children: ReactNode;
  fallback?: ReactNode;
  sectionName?: string;
};

type State = {
  hasError: boolean;
};

export class DashboardErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Dashboard section error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }
      return (
        <div className={styles.wrap}>
          <SectionState
            variant="error"
            message={this.props.sectionName ? `${this.props.sectionName} failed to load.` : 'This section failed to load.'}
          />
          <DashboardRefreshButton label="Retry" variant="ghost" className={styles.retryButton} />
        </div>
      );
    }
    return this.props.children;
  }
}

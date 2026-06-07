/**
 * @vitest-environment jsdom
 */
import { describe, expect, it, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { METRIC_HISTORY_STORAGE_KEY } from '../config';
import { useMetricHistory } from './use-metric-history';

describe('useMetricHistory', () => {
  beforeEach(() => {
    window.sessionStorage.clear();
  });

  it('records snapshot points and trims to max points', () => {
    const { result } = renderHook(() => useMetricHistory());

    act(() => {
      for (let i = 0; i < 65; i += 1) {
        result.current.recordSnapshot({
          pushSendsSuccess: i,
          pushSendsFailure: 0,
          pushQueueDepth: i,
          pushDeadLetterCount: 0,
          mapOutboxPending: 0,
          requestsFailed: 0,
          emailQueueDepth: 0,
          capturedAt: new Date(Date.now() + i * 1000).toISOString(),
        });
      }
    });

    expect(result.current.getSeries('pushSendsSuccess')).toHaveLength(60);
    expect(result.current.getSeries('pushSendsSuccess').at(-1)?.v).toBe(64);
    expect(window.sessionStorage.getItem(METRIC_HISTORY_STORAGE_KEY)).toBeTruthy();
  });
});

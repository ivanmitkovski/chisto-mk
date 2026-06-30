/**
 * @vitest-environment jsdom
 */
import { act, renderHook } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useNewsAltTextSave } from './use-news-alt-text-save';

describe('useNewsAltTextSave', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('debounces and flushes alt saves', async () => {
    const update = vi.fn().mockResolvedValue(undefined);
    const { result } = renderHook(() => useNewsAltTextSave(update));

    act(() => {
      result.current.scheduleAltSave('media-1', 'en', { en: 'Cover alt' });
    });

    expect(result.current.altPending).toBe(true);

    await act(async () => {
      vi.advanceTimersByTime(500);
      await Promise.resolve();
    });

    expect(update).toHaveBeenCalledWith('media-1', { en: 'Cover alt' });
    expect(result.current.altPending).toBe(false);
  });

  it('calls onError when flush fails', async () => {
    const error = new Error('network');
    const update = vi.fn().mockRejectedValue(error);
    const onError = vi.fn();
    const { result } = renderHook(() => useNewsAltTextSave(update, { onError }));

    act(() => {
      result.current.scheduleAltSave('media-1', 'en', { en: 'Alt' });
    });

    await act(async () => {
      try {
        await result.current.flushAltSaves();
      } catch {
        // expected
      }
    });

    expect(onError).toHaveBeenCalledWith(error);
  });
});

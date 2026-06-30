'use client';

import { useCallback, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { ApiError } from '@/lib/api';

type OptimisticMutationOptions<TData, TVariables> = {
  mutate: (variables: TVariables) => Promise<TData>;
  onSuccess?: (data: TData, variables: TVariables) => void;
  onError?: (error: unknown, variables: TVariables) => void;
  successToast?: { title: string; message?: string };
  errorToast?: { title: string; message?: string };
};

function mapApiErrorToMessage(
  error: ApiError,
  tErrors: ReturnType<typeof useTranslations<'errors'>>,
  fallback: string,
): string {
  if (error.status === 401 || error.status === 403) {
    return tErrors('sessionExpiredOrDenied');
  }
  if (error.status === 422) {
    return tErrors('validationFailed');
  }
  if (error.code === 'RATE_LIMITED') {
    return tErrors('apiReturnedError');
  }
  return error.message || fallback;
}

export function useOptimisticMutation<TData, TVariables>({
  mutate,
  onSuccess,
  onError,
  successToast,
  errorToast,
}: OptimisticMutationOptions<TData, TVariables>) {
  const [isPending, setIsPending] = useState(false);
  const isPendingRef = useRef(false);
  const { showToast } = useToast();
  const tErrors = useTranslations('errors');

  const run = useCallback(
    async (
      variables: TVariables,
      options?: {
        optimistic?: () => void;
        rollback?: () => void;
      },
    ): Promise<TData | null> => {
      if (isPendingRef.current) {
        return null;
      }
      isPendingRef.current = true;
      setIsPending(true);
      options?.optimistic?.();
      try {
        const data = await mutate(variables);
        onSuccess?.(data, variables);
        if (successToast) {
          showToast({
            tone: 'success',
            title: successToast.title,
            message: successToast.message ?? '',
          });
        }
        return data;
      } catch (error) {
        options?.rollback?.();
        onError?.(error, variables);
        const fallback =
          errorToast?.message ?? tErrors('somethingWentWrongTryAgain');
        const message =
          error instanceof ApiError
            ? mapApiErrorToMessage(error, tErrors, fallback)
            : error instanceof Error
              ? error.message
              : fallback;
        showToast({
          tone: 'warning',
          title: errorToast?.title ?? 'Action failed',
          message,
        });
        return null;
      } finally {
        isPendingRef.current = false;
        setIsPending(false);
      }
    },
    [mutate, onSuccess, onError, successToast, errorToast, showToast, tErrors],
  );

  return { run, isPending };
}

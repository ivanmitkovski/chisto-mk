'use client';

import { useRouter } from 'next/navigation';

type NewsErrorRetryButtonProps = {
  label: string;
  ariaDescribedBy?: string;
};

export function NewsErrorRetryButton({ label, ariaDescribedBy }: NewsErrorRetryButtonProps) {
  const router = useRouter();

  return (
    <button
      type="button"
      onClick={() => router.refresh()}
      aria-describedby={ariaDescribedBy}
      className="text-sm font-semibold text-primary underline-offset-4 transition-colors hover:text-primary-600 hover:underline"
    >
      {label}
    </button>
  );
}

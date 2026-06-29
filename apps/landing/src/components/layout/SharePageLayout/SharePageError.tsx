"use client";

import { PageErrorPanel } from "@/components/molecules/PageErrorPanel";

export function SharePageError({
  title,
  body,
  retryLabel,
  reset,
}: {
  title: string;
  body: string;
  retryLabel: string;
  reset: () => void;
}) {
  return (
    <main className="mx-auto flex min-h-dvh max-w-lg items-center px-6 py-10 font-sans">
      <PageErrorPanel title={title} body={body} retryLabel={retryLabel} onRetry={() => reset()} className="w-full" />
    </main>
  );
}

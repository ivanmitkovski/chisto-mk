import { PageLoadingSkeleton } from "@/components/molecules/PageLoadingSkeleton";

export function SharePageLoading({ srLabel }: { srLabel: string }) {
  return (
    <main className="mx-auto min-h-dvh max-w-lg px-6 py-10 font-sans">
      <PageLoadingSkeleton srLabel={srLabel} lines={5} />
    </main>
  );
}

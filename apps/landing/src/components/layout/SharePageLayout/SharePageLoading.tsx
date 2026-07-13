import { PageLoadingSkeleton } from "@/components/molecules/PageLoadingSkeleton";

export function SharePageLoading({ srLabel }: { srLabel: string }) {
  return (
    <main className="mx-auto min-h-dvh max-w-lg bg-[#F4F5F7] px-6 py-10 font-sans">
      <PageLoadingSkeleton srLabel={srLabel} lines={5} />
    </main>
  );
}

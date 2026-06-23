import Link from "next/link";

export default function NotFound() {
  return (
    <main className="grid min-h-dvh place-items-center bg-gray-50 px-8 font-sans">
      <div className="text-center">
        <p className="text-lg text-gray-700">Not found.</p>
        <Link
          href="/mk"
          className="mt-4 inline-block font-semibold text-primary underline-offset-2 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
        >
          Chisto.mk
        </Link>
      </div>
    </main>
  );
}

import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/routing";
import { DownloadCTA } from "@/components/molecules/DownloadCTA";

export default async function NotFoundPage() {
  const t = await getTranslations("notFound");

  return (
    <div className="flex min-h-[70vh] flex-col items-center justify-center px-4 font-sans">
      <h1 className="text-5xl font-bold text-gray-900 md:text-6xl">404</h1>
      <p className="mt-4 text-center text-lg text-gray-600">{t("title")}</p>
      <p className="mt-2 max-w-md text-center text-sm text-gray-500">{t("body")}</p>
      <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
        <Link
          href="/"
          className="inline-flex items-center justify-center rounded-full bg-primary px-8 py-3 font-medium text-white transition-colors hover:bg-primary-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
        >
          {t("home")}
        </Link>
        <DownloadCTA variant="secondary" size="md" analyticsSource="not_found" />
      </div>
    </div>
  );
}

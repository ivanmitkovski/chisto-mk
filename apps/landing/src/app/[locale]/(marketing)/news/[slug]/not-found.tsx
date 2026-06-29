import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/routing";

export default async function NewsArticleNotFound() {
  const t = await getTranslations("newsPage.notFound");

  return (
    <div className="flex min-h-[70vh] flex-col items-center justify-center px-4 font-sans">
      <h1 className="text-5xl font-bold text-gray-900 md:text-6xl">404</h1>
      <p className="mt-4 text-center text-lg text-gray-600">{t("articleTitle")}</p>
      <p className="mt-2 max-w-md text-center text-sm text-gray-500">{t("articleBody")}</p>
      <Link
        href="/news"
        className="mt-8 inline-flex items-center justify-center rounded-full bg-primary px-8 py-3 font-medium text-white transition-colors hover:bg-primary-600"
      >
        {t("backToNews")}
      </Link>
    </div>
  );
}

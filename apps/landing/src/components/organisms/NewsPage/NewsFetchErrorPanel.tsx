import { NewsErrorRetryButton } from "./NewsErrorRetryButton";

type NewsFetchErrorPanelProps = {
  title: string;
  body: string;
  retryLabel: string;
};

export function NewsFetchErrorPanel({ title, body, retryLabel }: NewsFetchErrorPanelProps) {
  return (
    <div className="mx-auto max-w-2xl rounded-2xl border border-red-200/90 bg-red-50/90 p-8 shadow-sm md:p-10">
      <h1 className="text-lg font-bold text-gray-900">{title}</h1>
      <p className="mt-3 leading-relaxed text-gray-600">{body}</p>
      <p className="mt-6">
        <NewsErrorRetryButton label={retryLabel} />
      </p>
    </div>
  );
}

/**
 * Shared text-field chrome for marketing forms.
 * Keep font-size at text-base (1rem / 16px): iOS Safari zooms the page when
 * focused controls render below 16px. Do not use text-sm/text-xs on these.
 */
export const formControlClassName =
  "w-full rounded-xl border border-gray-200 bg-gray-50 px-4 py-3.5 text-base leading-normal text-gray-900 outline-none transition-[border-color,box-shadow] placeholder:text-gray-400 focus:border-primary focus:bg-white focus:ring-2 focus:ring-primary/25";

export const formControlErrorClassName =
  "border-red-400 focus:border-red-400 focus:ring-red-400/40";

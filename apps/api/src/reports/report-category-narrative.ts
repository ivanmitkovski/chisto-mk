/** Human labels for API category keys; matches mobile `ReportCategory.label`. */
const REPORT_CATEGORY_LABEL_BY_KEY: Readonly<Record<string, string>> = {
  ILLEGAL_LANDFILL: 'Illegal landfill',
  WATER_POLLUTION: 'Water pollution',
  AIR_POLLUTION: 'Air pollution',
  INDUSTRIAL_WASTE: 'Industrial waste',
  OTHER: 'Other',
};

/**
 * Removes a leading `"{label}:"` prefix when it matches the report category.
 * Mobile historically concatenated category into `Report.description`.
 */
export function stripCategoryLabelPrefix(
  text: string | null | undefined,
  categoryKey: string | null | undefined,
): string {
  if (text == null || text === '') return '';
  const label = categoryKey ? REPORT_CATEGORY_LABEL_BY_KEY[categoryKey] : undefined;
  if (!label) return text.trim();
  const trimmed = text.trim();
  const prefix = `${label}:`;
  if (trimmed.length < prefix.length) return trimmed;
  if (!trimmed.toLowerCase().startsWith(prefix.toLowerCase())) return trimmed;
  return trimmed.substring(prefix.length).trimStart().trim();
}

/**
 * Client-side list search debounce (ms). Keep within 250–400ms to limit filter churn.
 * - Reports list: debounced client filter (this constant).
 * - Users: URL + server fetch on blur/Enter — see users-workspace.
 * - Audit: filters apply via button — no debounce unless auto-apply is added.
 */
export const ADMIN_SEARCH_DEBOUNCE_MS = 300;

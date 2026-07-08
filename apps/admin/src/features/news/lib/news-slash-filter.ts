/** Simple subsequence fuzzy match (case-insensitive). */
export function fuzzyMatchSubsequence(query: string, target: string): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  const hay = target.toLowerCase();
  let qi = 0;
  for (let i = 0; i < hay.length && qi < q.length; i += 1) {
    if (hay[i] === q[qi]) qi += 1;
  }
  return qi === q.length;
}

export function fuzzyScore(query: string, target: string): number {
  const q = query.trim().toLowerCase();
  if (!q) return 0;
  if (!fuzzyMatchSubsequence(q, target)) return -1;
  const hay = target.toLowerCase();
  let qi = 0;
  let score = 0;
  for (let i = 0; i < hay.length && qi < q.length; i += 1) {
    if (hay[i] === q[qi]) {
      score += hay.startsWith(q, i) ? 4 : 1;
      qi += 1;
    }
  }
  return score + (hay.includes(q) ? 2 : 0);
}

import type { ResolvedCommand, ScoredCommand } from './types';

const RECENT_SCORE_BOOST = 50;

function normalize(value: string): string {
  return value.trim().toLowerCase();
}

function tokenizeQuery(query: string): string[] {
  return normalize(query).split(/\s+/).filter(Boolean);
}

function scoreField(text: string, tokens: string[], weight: number): { score: number; match?: { start: number; end: number } } {
  const normalized = normalize(text);
  if (!normalized) return { score: 0 };

  let total = 0;
  let bestMatch: { start: number; end: number } | undefined;

  for (const token of tokens) {
    const index = normalized.indexOf(token);
    if (index === -1) {
      const fuzzy = fuzzySubsequenceScore(normalized, token);
      if (fuzzy <= 0) return { score: 0 };
      total += fuzzy * weight;
      continue;
    }

    const wordBonus = index === 0 || normalized[index - 1] === ' ' || normalized[index - 1] === '/' ? 8 : 0;
    total += (token.length * 10 + wordBonus) * weight;
    if (!bestMatch) {
      bestMatch = { start: index, end: index + token.length };
    }
  }

  return { score: total, ...(bestMatch ? { match: bestMatch } : {}) };
}

function fuzzySubsequenceScore(haystack: string, needle: string): number {
  if (!needle) return 0;
  let hi = 0;
  let matches = 0;
  for (let ni = 0; ni < needle.length; ni += 1) {
    const ch = needle[ni];
    while (hi < haystack.length && haystack[hi] !== ch) hi += 1;
    if (hi >= haystack.length) return 0;
    matches += 1;
    hi += 1;
  }
  return matches * 2;
}

function isPathQuery(query: string): boolean {
  const q = query.trim();
  return q.startsWith('/') || q.includes('/dashboard');
}

export function searchCommands(
  commands: ResolvedCommand[],
  query: string,
  recentIds: string[] = [],
): ScoredCommand[] {
  const normalizedQuery = normalize(query);
  if (!normalizedQuery) {
    const recentSet = new Set(recentIds);
    return commands
      .map((command) => ({
        command,
        score: recentSet.has(command.id) ? RECENT_SCORE_BOOST : command.group === 'navigation' ? 1 : 0,
      }))
      .sort((a, b) => b.score - a.score);
  }

  const tokens = tokenizeQuery(query);
  const pathMode = isPathQuery(query);
  const recentSet = new Set(recentIds);

  const scored: ScoredCommand[] = [];

  for (const command of commands) {
    let score = command.scoreBoost ?? 0;
    if (recentSet.has(command.id)) score += RECENT_SCORE_BOOST;

    const labelResult = scoreField(command.label, tokens, 1);
    if (labelResult.score === 0 && tokens.length > 0) {
      const descResult = scoreField(command.description ?? '', tokens, 0.7);
      if (descResult.score === 0) {
        const hrefResult = scoreField(command.href ?? '', tokens, pathMode ? 1.2 : 0.6);
        if (hrefResult.score === 0) {
          const keywordText = command.searchKeywords.join(' ');
          const kwResult = scoreField(keywordText, tokens, 0.5);
          if (kwResult.score === 0) continue;
          score += kwResult.score;
        } else {
          score += hrefResult.score;
        }
      } else {
        score += descResult.score;
      }
    } else {
      score += labelResult.score;
    }

    scored.push({
      command,
      score,
      ...(labelResult.match ? { labelMatch: labelResult.match } : {}),
    });
  }

  return scored.sort((a, b) => b.score - a.score);
}

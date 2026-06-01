/// Text normalization helpers for map search (local match + highlight).
library;

const Map<String, String> _cyrillicToLatin = <String, String>{
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'ѓ': 'g',
  'е': 'e',
  'ж': 'z',
  'з': 'z',
  'ѕ': 'z',
  'и': 'i',
  'ј': 'j',
  'к': 'k',
  'л': 'l',
  'љ': 'l',
  'м': 'm',
  'н': 'n',
  'њ': 'n',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'ќ': 'k',
  'у': 'u',
  'ф': 'f',
  'х': 'h',
  'ц': 'c',
  'ч': 'c',
  'џ': 'd',
  'ш': 's',
};

String normalizeMapSearchText(String input) {
  final String collapsed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  return collapsed.toLowerCase();
}

String foldMapSearchText(String input) {
  final StringBuffer out = StringBuffer();
  for (final int codeUnit in normalizeMapSearchText(input).runes) {
    final String char = String.fromCharCode(codeUnit);
    out.write(_cyrillicToLatin[char] ?? char);
  }
  return out.toString();
}

List<String> mapSearchTerms(String rawQuery) {
  return normalizeMapSearchText(
    rawQuery,
  ).split(' ').where((String term) => term.isNotEmpty).toList();
}

bool mapSearchHaystackMatchesTerms(String haystack, List<String> terms) {
  if (terms.isEmpty) {
    return true;
  }
  final String folded = foldMapSearchText(haystack);
  for (final String term in terms) {
    if (!folded.contains(foldMapSearchText(term))) {
      return false;
    }
  }
  return true;
}

int mapSearchTitleRank(String title, String rawQuery) {
  final String q = normalizeMapSearchText(rawQuery);
  final String foldedTitle = foldMapSearchText(title);
  final String foldedQuery = foldMapSearchText(q);
  if (foldedTitle == foldedQuery) {
    return 0;
  }
  if (foldedTitle.startsWith(foldedQuery)) {
    return 1;
  }
  return 2;
}

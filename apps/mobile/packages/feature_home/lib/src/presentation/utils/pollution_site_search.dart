import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/utils/map_search_text.dart';

String pollutionSiteSearchHaystack(PollutionSite site) {
  final List<String> parts = <String>[
    site.title,
    site.description,
    if (site.pollutionType != null) site.pollutionType!,
    if (site.firstReport?.title.isNotEmpty ?? false) site.firstReport!.title,
    if (site.firstReport?.description?.isNotEmpty ?? false)
      site.firstReport!.description!,
  ];
  return parts.join(' ');
}

bool pollutionSiteMatchesSearchTerms(PollutionSite site, List<String> terms) {
  return mapSearchHaystackMatchesTerms(
    pollutionSiteSearchHaystack(site),
    terms,
  );
}

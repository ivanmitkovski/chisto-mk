/// Default site title returned by the API when no custom title exists yet.
///
/// This is an English API sentinel, not localized UI copy.
const String kApiDefaultPollutionSiteTitle = 'Pollution site';

bool isApiDefaultPollutionSiteTitle(String? title) {
  final String trimmed = title?.trim() ?? '';
  return trimmed.isEmpty || trimmed == kApiDefaultPollutionSiteTitle;
}

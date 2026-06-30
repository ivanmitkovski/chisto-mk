const String _kDefaultLightTileUrl =
    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
const String _kDefaultDarkTileUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

class MapTileConfig {
  const MapTileConfig._();

  static const String lightTileUrl = String.fromEnvironment(
    'MAP_TILE_URL_LIGHT',
    defaultValue: _kDefaultLightTileUrl,
  );

  static const String darkTileUrl = String.fromEnvironment(
    'MAP_TILE_URL_DARK',
    defaultValue: _kDefaultDarkTileUrl,
  );

  static const List<String> subdomains = <String>['a', 'b', 'c', 'd'];

  static String tileUrl({required bool dark}) =>
      dark ? darkTileUrl : lightTileUrl;
}

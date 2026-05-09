import 'package:chisto_mobile/features/home/data/map_regions/map_region_names_catalog.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Localized map for [MacedoniaMapRegions] ids (en/mk/sq via ARB).
String mapGeoRegionTitle(AppLocalizations l10n, String id) {
  final String? curated = mapRegionNameForLocale(
    id: id,
    localeName: l10n.localeName,
  );
  if (curated != null) {
    return curated;
  }

  switch (id) {
    case 'skopje':
      return l10n.mapGeoSkopje;
    case 'skopje_centar':
      return l10n.mapGeoSkopjeCentar;
    case 'skopje_aerodrom':
      return l10n.mapGeoSkopjeAerodrom;
    case 'skopje_karposh':
      return l10n.mapGeoSkopjeKarposh;
    case 'skopje_chair':
      return l10n.mapGeoSkopjeChair;
    case 'skopje_kisela_voda':
      return l10n.mapGeoSkopjeKiselaVoda;
    case 'skopje_gazi_baba':
      return l10n.mapGeoSkopjeGaziBaba;
    case 'skopje_butel':
      return l10n.mapGeoSkopjeButel;
    case 'skopje_gjorce_petrov':
      return l10n.mapGeoSkopjeGjorcePetrov;
    case 'skopje_saraj':
      return l10n.mapGeoSkopjeSaraj;
    case 'bitola':
      return l10n.mapGeoBitola;
    case 'kumanovo':
      return l10n.mapGeoKumanovo;
    case 'prilep':
      return l10n.mapGeoPrilep;
    case 'tetovo':
      return l10n.mapGeoTetovo;
    case 'veles':
      return l10n.mapGeoVeles;
    case 'ohrid':
      return l10n.mapGeoOhrid;
    case 'stip':
      return l10n.mapGeoStip;
    case 'gostivar':
      return l10n.mapGeoGostivar;
    case 'strumica':
      return l10n.mapGeoStrumica;
    case 'kavadarci':
      return l10n.mapGeoKavadarci;
    case 'kocani':
      return l10n.mapGeoKocani;
    case 'struga':
      return l10n.mapGeoStruga;
    case 'radovis':
      return l10n.mapGeoRadovis;
    case 'gevgelija':
      return l10n.mapGeoGevgelija;
    case 'kriva_palanka':
      return l10n.mapGeoKrivaPalanka;
    case 'sveti_nikole':
      return l10n.mapGeoSvetiNikole;
    case 'vinica':
      return l10n.mapGeoVinica;
    case 'delcevo':
      return l10n.mapGeoDelcevo;
    case 'probistip':
      return l10n.mapGeoProbistip;
    case 'berovo':
      return l10n.mapGeoBerovo;
    case 'kratovo':
      return l10n.mapGeoKratovo;
    case 'kicevo':
      return l10n.mapGeoKicevo;
    case 'makedonski_brod':
      return l10n.mapGeoMakedonskiBrod;
    case 'negotino':
      return l10n.mapGeoNegotino;
    case 'resen':
      return l10n.mapGeoResen;
    default:
      return l10n.mapGeoUnknownArea;
  }
}

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const List<String> mapRootRegionIds = <String>[
  'skopje',
  'arachinovo',
  'berovo',
  'bitola',
  'bogdantsi',
  'bogovinje',
  'bosilovo',
  'brvenitsa',
  'centar_zhupa',
  'chashka',
  'cheshinovo_obleshevo',
  'chucher_sandevo',
  'debar',
  'debartsa',
  'delcevo',
  'demir_hisar',
  'demir_kapija',
  'dojran',
  'dolneni',
  'drugovo',
  'gevgelija',
  'gostivar',
  'gradsko',
  'ilinden',
  'jegunovtse',
  'karbintsi',
  'kavadarci',
  'kicevo',
  'kocani',
  'konche',
  'kratovo',
  'kriva_palanka',
  'krivogashtani',
  'krushevo',
  'kumanovo',
  'lipkovo',
  'lozovo',
  'makedonska_kamenitsa',
  'makedonski_brod',
  'mavrovo_and_rostusha',
  'mogila',
  'negotino',
  'novatsi',
  'novo_selo',
  'ohrid',
  'oslomej',
  'pehchevo',
  'petrovets',
  'plasnitsa',
  'prilep',
  'probistip',
  'radovis',
  'rankovtse',
  'resen',
  'rosoman',
  'sopishte',
  'staro_nagorichane',
  'stip',
  'struga',
  'strumica',
  'studenichani',
  'sveti_nikole',
  'teartse',
  'tetovo',
  'valandovo',
  'vasilevo',
  'veles',
  'vevchani',
  'vinica',
  'vraneshtitsa',
  'vrapchishte',
  'zajas',
  'zelenikovo',
  'zhelino',
  'zrnovtsi',
];

const List<String> mapSkopjeMunicipalityIds = <String>[
  'skopje',
  'skopje_centar',
  'skopje_aerodrom',
  'skopje_karposh',
  'skopje_chair',
  'skopje_kisela_voda',
  'skopje_gazi_baba',
  'skopje_butel',
  'skopje_gjorce_petrov',
  'skopje_saraj',
  'skopje_shuto_orizari',
];

final Map<String, LatLngBounds> mapRegionBounds = <String, LatLngBounds>{
  'arachinovo': LatLngBounds(
    const LatLng(42.001842, 21.546428),
    const LatLng(42.081565, 21.644344),
  ),
  'berovo': LatLngBounds(
    const LatLng(41.517960, 22.637195),
    const LatLng(41.821196, 23.013761),
  ),
  'bitola': LatLngBounds(
    const LatLng(40.859411, 21.068324),
    const LatLng(41.228150, 21.513731),
  ),
  'bogdantsi': LatLngBounds(
    const LatLng(41.126569, 22.509592),
    const LatLng(41.258757, 22.670898),
  ),
  'bogovinje': LatLngBounds(
    const LatLng(41.884444, 20.754744),
    const LatLng(42.009473, 20.984854),
  ),
  'bosilovo': LatLngBounds(
    const LatLng(41.390723, 22.691316),
    const LatLng(41.571838, 22.875420),
  ),
  'brvenitsa': LatLngBounds(
    const LatLng(41.792197, 20.944192),
    const LatLng(41.984007, 21.190852),
  ),
  'centar_zhupa': LatLngBounds(
    const LatLng(41.409842, 20.520159),
    const LatLng(41.532206, 20.682323),
  ),
  'chashka': LatLngBounds(
    const LatLng(41.435220, 21.369408),
    const LatLng(41.768416, 21.818120),
  ),
  'cheshinovo_obleshevo': LatLngBounds(
    const LatLng(41.803509, 22.204636),
    const LatLng(41.946282, 22.407788),
  ),
  'chucher_sandevo': LatLngBounds(
    const LatLng(42.042610, 21.302390),
    const LatLng(42.249191, 21.523539),
  ),
  'debar': LatLngBounds(
    const LatLng(41.408458, 20.453139),
    const LatLng(41.582002, 20.729025),
  ),
  'debartsa': LatLngBounds(
    const LatLng(41.160499, 20.681577),
    const LatLng(41.443333, 21.017893),
  ),
  'delcevo': LatLngBounds(
    const LatLng(41.803099, 22.618214),
    const LatLng(42.073034, 22.901624),
  ),
  'demir_hisar': LatLngBounds(
    const LatLng(41.124553, 20.954244),
    const LatLng(41.393783, 21.297608),
  ),
  'demir_kapija': LatLngBounds(
    const LatLng(41.289994, 22.102373),
    const LatLng(41.496945, 22.370470),
  ),
  'dojran': LatLngBounds(
    const LatLng(41.139529, 22.574343),
    const LatLng(41.310923, 22.766049),
  ),
  'dolneni': LatLngBounds(
    const LatLng(41.357578, 21.255811),
    const LatLng(41.605521, 21.607868),
  ),
  'drugovo': LatLngBounds(
    const LatLng(41.323896, 20.688197),
    const LatLng(41.591819, 21.134504),
  ),
  'gevgelija': LatLngBounds(
    const LatLng(41.117296, 22.214016),
    const LatLng(41.388115, 22.605696),
  ),
  'gostivar': LatLngBounds(
    const LatLng(41.641552, 20.558991),
    const LatLng(41.877328, 21.088032),
  ),
  'gradsko': LatLngBounds(
    const LatLng(41.492211, 21.780359),
    const LatLng(41.734498, 21.980242),
  ),
  'ilinden': LatLngBounds(
    const LatLng(41.936921, 21.529365),
    const LatLng(42.058335, 21.700763),
  ),
  'jegunovtse': LatLngBounds(
    const LatLng(41.994300, 21.027942),
    const LatLng(42.206382, 21.216232),
  ),
  'karbintsi': LatLngBounds(
    const LatLng(41.719002, 22.135300),
    const LatLng(41.875308, 22.469821),
  ),
  'kavadarci': LatLngBounds(
    const LatLng(41.100244, 21.772809),
    const LatLng(41.517530, 22.299714),
  ),
  'kicevo': LatLngBounds(
    const LatLng(41.479246, 20.888344),
    const LatLng(41.564259, 21.002014),
  ),
  'kocani': LatLngBounds(
    const LatLng(41.861510, 22.253647),
    const LatLng(42.125803, 22.549680),
  ),
  'konche': LatLngBounds(
    const LatLng(41.430029, 22.266380),
    const LatLng(41.610885, 22.522379),
  ),
  'kratovo': LatLngBounds(
    const LatLng(42.008440, 21.928786),
    const LatLng(42.187724, 22.387847),
  ),
  'kriva_palanka': LatLngBounds(
    const LatLng(42.113837, 22.132806),
    const LatLng(42.373789, 22.516224),
  ),
  'krivogashtani': LatLngBounds(
    const LatLng(41.250738, 21.304700),
    const LatLng(41.396721, 21.432075),
  ),
  'krushevo': LatLngBounds(
    const LatLng(41.226724, 21.127432),
    const LatLng(41.473542, 21.340294),
  ),
  'kumanovo': LatLngBounds(
    const LatLng(41.960567, 21.609966),
    const LatLng(42.266524, 22.007941),
  ),
  'lipkovo': LatLngBounds(
    const LatLng(42.051145, 21.432903),
    const LatLng(42.280056, 21.701480),
  ),
  'lozovo': LatLngBounds(
    const LatLng(41.655841, 21.828730),
    const LatLng(41.855852, 22.025350),
  ),
  'makedonska_kamenitsa': LatLngBounds(
    const LatLng(41.955434, 22.451838),
    const LatLng(42.155158, 22.661196),
  ),
  'makedonski_brod': LatLngBounds(
    const LatLng(41.435109, 21.010857),
    const LatLng(41.853153, 21.397450),
  ),
  'mavrovo_and_rostusha': LatLngBounds(
    const LatLng(41.490068, 20.514093),
    const LatLng(41.797864, 20.901994),
  ),
  'mogila': LatLngBounds(
    const LatLng(41.083317, 21.290665),
    const LatLng(41.272591, 21.597707),
  ),
  'negotino': LatLngBounds(
    const LatLng(41.353914, 21.953987),
    const LatLng(41.675902, 22.314205),
  ),
  'novatsi': LatLngBounds(
    const LatLng(40.866002, 21.428982),
    const LatLng(41.171211, 21.912030),
  ),
  'novo_selo': LatLngBounds(
    const LatLng(41.334342, 22.790685),
    const LatLng(41.530935, 22.979478),
  ),
  'ohrid': LatLngBounds(
    const LatLng(40.898333, 20.732456),
    const LatLng(41.263692, 21.039127),
  ),
  'oslomej': LatLngBounds(
    const LatLng(41.514318, 20.966552),
    const LatLng(41.665146, 21.106120),
  ),
  'pehchevo': LatLngBounds(
    const LatLng(41.690603, 22.782909),
    const LatLng(41.877877, 23.032498),
  ),
  'petrovets': LatLngBounds(
    const LatLng(41.818391, 21.569873),
    const LatLng(42.001025, 21.821309),
  ),
  'plasnitsa': LatLngBounds(
    const LatLng(41.417176, 21.030498),
    const LatLng(41.490950, 21.187384),
  ),
  'prilep': LatLngBounds(
    const LatLng(41.078736, 21.363723),
    const LatLng(41.486566, 21.932148),
  ),
  'probistip': LatLngBounds(
    const LatLng(41.857074, 22.024753),
    const LatLng(42.070750, 22.361001),
  ),
  'radovis': LatLngBounds(
    const LatLng(41.514589, 22.309220),
    const LatLng(41.787294, 22.661365),
  ),
  'rankovtse': LatLngBounds(
    const LatLng(42.110516, 22.033649),
    const LatLng(42.312343, 22.236691),
  ),
  'resen': LatLngBounds(
    const LatLng(40.854683, 20.829072),
    const LatLng(41.215006, 21.255476),
  ),
  'rosoman': LatLngBounds(
    const LatLng(41.436873, 21.810865),
    const LatLng(41.562898, 22.000094),
  ),
  'skopje': LatLngBounds(
    const LatLng(41.894167, 21.149874),
    const LatLng(42.157751, 21.589840),
  ),
  'skopje_aerodrom': LatLngBounds(
    const LatLng(41.941335, 21.441828),
    const LatLng(41.994780, 21.561969),
  ),
  'skopje_butel': LatLngBounds(
    const LatLng(42.016600, 21.388846),
    const LatLng(42.157751, 21.512243),
  ),
  'skopje_centar': LatLngBounds(
    const LatLng(41.977982, 21.405618),
    const LatLng(42.014336, 21.451060),
  ),
  'skopje_chair': LatLngBounds(
    const LatLng(41.998744, 21.426719),
    const LatLng(42.022545, 21.451060),
  ),
  'skopje_gazi_baba': LatLngBounds(
    const LatLng(41.930500, 21.446632),
    const LatLng(42.126163, 21.589840),
  ),
  'skopje_gjorce_petrov': LatLngBounds(
    const LatLng(41.997099, 21.247652),
    const LatLng(42.108851, 21.377208),
  ),
  'skopje_karposh': LatLngBounds(
    const LatLng(41.963626, 21.357942),
    const LatLng(42.045167, 21.440492),
  ),
  'skopje_kisela_voda': LatLngBounds(
    const LatLng(41.911140, 21.426420),
    const LatLng(41.988608, 21.553396),
  ),
  'skopje_saraj': LatLngBounds(
    const LatLng(41.894167, 21.149874),
    const LatLng(42.110915, 21.368437),
  ),
  'skopje_shuto_orizari': LatLngBounds(
    const LatLng(42.027468, 21.392159),
    const LatLng(42.070747, 21.434380),
  ),
  'sopishte': LatLngBounds(
    const LatLng(41.731290, 21.216137),
    const LatLng(41.965873, 21.462682),
  ),
  'staro_nagorichane': LatLngBounds(
    const LatLng(42.119518, 21.767894),
    const LatLng(42.343516, 22.069383),
  ),
  'stip': LatLngBounds(
    const LatLng(41.549020, 21.947120),
    const LatLng(41.885372, 22.415623),
  ),
  'struga': LatLngBounds(
    const LatLng(41.086513, 20.494444),
    const LatLng(41.430448, 20.766739),
  ),
  'strumica': LatLngBounds(
    const LatLng(41.315983, 22.456557),
    const LatLng(41.499908, 22.808500),
  ),
  'studenichani': LatLngBounds(
    const LatLng(41.703782, 21.337523),
    const LatLng(41.946945, 21.594323),
  ),
  'sveti_nikole': LatLngBounds(
    const LatLng(41.731310, 21.805880),
    const LatLng(42.021736, 22.125928),
  ),
  'teartse': LatLngBounds(
    const LatLng(42.026145, 20.927788),
    const LatLng(42.167500, 21.136833),
  ),
  'tetovo': LatLngBounds(
    const LatLng(41.962557, 20.748109),
    const LatLng(42.128273, 21.052814),
  ),
  'valandovo': LatLngBounds(
    const LatLng(41.216894, 22.334274),
    const LatLng(41.458627, 22.780016),
  ),
  'vasilevo': LatLngBounds(
    const LatLng(41.460908, 22.507804),
    const LatLng(41.644596, 22.767483),
  ),
  'veles': LatLngBounds(
    const LatLng(41.612075, 21.578629),
    const LatLng(41.919700, 21.880540),
  ),
  'vevchani': LatLngBounds(
    const LatLng(41.224247, 20.517237),
    const LatLng(41.263480, 20.647301),
  ),
  'vinica': LatLngBounds(
    const LatLng(41.727843, 22.451860),
    const LatLng(41.991587, 22.734933),
  ),
  'vraneshtitsa': LatLngBounds(
    const LatLng(41.421389, 20.959921),
    const LatLng(41.584555, 21.135948),
  ),
  'vrapchishte': LatLngBounds(
    const LatLng(41.815133, 20.727973),
    const LatLng(41.934433, 20.948473),
  ),
  'zajas': LatLngBounds(
    const LatLng(41.530048, 20.778336),
    const LatLng(41.675328, 20.986754),
  ),
  'zelenikovo': LatLngBounds(
    const LatLng(41.749320, 21.468509),
    const LatLng(41.914679, 21.653407),
  ),
  'zhelino': LatLngBounds(
    const LatLng(41.830002, 21.008437),
    const LatLng(42.023441, 21.242412),
  ),
  'zrnovtsi': LatLngBounds(
    const LatLng(41.793764, 22.374343),
    const LatLng(41.880660, 22.476797),
  ),
};

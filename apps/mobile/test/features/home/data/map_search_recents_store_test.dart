import 'package:chisto_mobile/features/home/data/map_search_recents_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('readSync returns empty when unset', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(MapSearchRecentsStore.readSync(prefs), isEmpty);
  });

  test('add dedupes case-insensitively and caps at five', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await MapSearchRecentsStore.add(prefs, 'Alpha');
    await MapSearchRecentsStore.add(prefs, 'alpha');
    await MapSearchRecentsStore.add(prefs, 'Beta');
    await MapSearchRecentsStore.add(prefs, 'Gamma');
    await MapSearchRecentsStore.add(prefs, 'Delta');
    await MapSearchRecentsStore.add(prefs, 'Epsilon');
    await MapSearchRecentsStore.add(prefs, 'Zeta');
    final List<String> rows = MapSearchRecentsStore.readSync(prefs);
    expect(rows.length, 5);
    expect(rows.first, 'Zeta');
    expect(rows.contains('Alpha'), isFalse);
  });

  test('add ignores very short terms', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await MapSearchRecentsStore.add(prefs, 'x');
    expect(MapSearchRecentsStore.readSync(prefs), isEmpty);
  });

  test('clear removes persisted recents', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await MapSearchRecentsStore.add(prefs, 'Alpha');
    expect(MapSearchRecentsStore.readSync(prefs), isNotEmpty);
    await MapSearchRecentsStore.clear(prefs);
    expect(MapSearchRecentsStore.readSync(prefs), isEmpty);
  });
}

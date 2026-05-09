import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SiteMapSearchRequest.toBodyJson omits empty optional arrays', () {
    const SiteMapSearchRequest req = SiteMapSearchRequest(
      query: 'test',
      limit: 10,
      lat: 41.0,
      lng: 21.0,
      statuses: <String>[],
      pollutionTypes: <String>[],
      includeArchived: false,
    );
    final Map<String, dynamic> json = req.toBodyJson();
    expect(json.containsKey('statuses'), isFalse);
    expect(json.containsKey('pollutionTypes'), isFalse);
    expect(json['includeArchived'], isFalse);
  });

  test('SiteMapSearchRequest.toBodyJson includes non-empty filters', () {
    const SiteMapSearchRequest req = SiteMapSearchRequest(
      query: 'waste',
      statuses: <String>['REPORTED'],
      pollutionTypes: <String>['PLASTIC'],
      includeArchived: true,
    );
    final Map<String, dynamic> json = req.toBodyJson();
    expect(json['statuses'], <String>['REPORTED']);
    expect(json['pollutionTypes'], <String>['PLASTIC']);
    expect(json['includeArchived'], isTrue);
  });

  test('SiteMapSearchRequest.toBodyJson drops ARCHIVED/UNKNOWN map chip codes', () {
    const SiteMapSearchRequest req = SiteMapSearchRequest(
      query: 'goce',
      statuses: <String>['REPORTED', 'ARCHIVED', 'UNKNOWN', 'VERIFIED'],
    );
    final Map<String, dynamic> json = req.toBodyJson();
    expect(json['statuses'], <String>['REPORTED', 'VERIFIED']);
  });
}

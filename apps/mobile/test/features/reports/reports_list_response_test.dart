import 'package:chisto_mobile/features/reports/domain/models/reports_list_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportsListResponse', () {
    test('hasMore is true when more pages exist', () {
      const ReportsListResponse r = ReportsListResponse(
        data: [],
        total: 100,
        page: 1,
        limit: 20,
      );
      expect(r.hasMore, isTrue);
    });

    test('hasMore is false on last full page', () {
      const ReportsListResponse r = ReportsListResponse(
        data: [],
        total: 40,
        page: 2,
        limit: 20,
      );
      expect(r.hasMore, isFalse);
    });
  });
}

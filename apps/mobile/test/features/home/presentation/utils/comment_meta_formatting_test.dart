import 'package:chisto_mobile/features/home/presentation/utils/comment_meta_formatting.dart';
import 'package:chisto_mobile/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('formatCommentMetaSubtitle', () {
    final AppLocalizationsEn l10n = AppLocalizationsEn();

    test('returns deleting line when isDeleting', () {
      final String s = formatCommentMetaSubtitle(
        l10n,
        DateTime.utc(2020),
        DateTime.utc(2026),
        isDeleting: true,
        isEditing: false,
        likeCount: 0,
      );
      expect(s, l10n.commentsStatusDeleting);
    });

    test('returns just now for sub-minute age', () {
      final DateTime now = DateTime.utc(2026, 4, 1, 12, 0, 0);
      final String s = formatCommentMetaSubtitle(
        l10n,
        now.subtract(const Duration(seconds: 30)),
        now,
        isDeleting: false,
        isEditing: false,
        likeCount: 0,
      );
      expect(s, l10n.commentsCommentMetaJustNow);
    });

    test('returns minutes ago in range', () {
      final DateTime now = DateTime.utc(2026, 4, 1, 12, 0, 0);
      final String s = formatCommentMetaSubtitle(
        l10n,
        now.subtract(const Duration(minutes: 15)),
        now,
        isDeleting: false,
        isEditing: false,
        likeCount: 0,
      );
      expect(s, l10n.commentsCommentMetaMinutesAgo(15));
    });

    test('returns date for old posts', () {
      final DateTime now = DateTime.utc(2026, 4, 1);
      final DateTime created = DateTime.utc(2025, 1, 10);
      final String s = formatCommentMetaSubtitle(
        l10n,
        created,
        now,
        isDeleting: false,
        isEditing: false,
        likeCount: 0,
      );
      expect(s.contains('2025'), isTrue);
    });
  });
}

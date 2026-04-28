import 'package:chisto_mobile/features/home/presentation/utils/comment_input_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeBody trims and strips simple tags', () {
    expect(CommentInputValidator.normalizeBody('   '), '');
    expect(
      CommentInputValidator.normalizeBody('  <b>Hi</b>  there  '),
      'Hi there',
    );
  });

  test('withinMaxLength', () {
    expect(CommentInputValidator.withinMaxLength('a' * 10), isTrue);
    expect(CommentInputValidator.withinMaxLength('a' * 2001), isFalse);
  });
}

import 'package:feature_home/src/presentation/utils/comment_input_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeBody trims and strips simple tags', () {
    expect(CommentInputValidator.normalizeBody('   '), '');
    expect(
      CommentInputValidator.normalizeBody('  <b>Hi</b>  there  '),
      'Hi there',
    );
  });

  test('maxBodyLength matches API limit', () {
    expect(CommentInputValidator.maxBodyLength, 500);
  });

  test('withinMaxLength uses maxBodyLength by default', () {
    expect(CommentInputValidator.withinMaxLength('a' * 10), isTrue);
    expect(CommentInputValidator.withinMaxLength('a' * 500), isTrue);
    expect(CommentInputValidator.withinMaxLength('a' * 501), isFalse);
  });

  test('normalizedLength counts normalized body', () {
    expect(CommentInputValidator.normalizedLength('  hi  '), 2);
  });
}

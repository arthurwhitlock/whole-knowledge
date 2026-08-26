import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/learning/review_submission_id.dart';

void main() {
  test('generates distinct UUID version 4 submission identifiers', () {
    final first = ReviewSubmissionId.generate();
    final second = ReviewSubmissionId.generate();
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    expect(first, matches(uuidV4));
    expect(second, matches(uuidV4));
    expect(second, isNot(first));
  });
}

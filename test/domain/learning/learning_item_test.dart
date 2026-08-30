import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  test('an unreviewed item with a future timestamp is not due', () {
    final item = learningItem(
      nextReviewAt: DateTime.utc(2026, 8, 27),
      reviewCount: 0,
    );

    expect(item.isDueAt(DateTime.utc(2026, 8, 25)), isFalse);
  });

  test('a reviewed item is due only at or after next review', () {
    final item = learningItem(
      nextReviewAt: DateTime.utc(2026, 8, 27),
      reviewCount: 1,
    );

    expect(item.isDueAt(DateTime.utc(2026, 8, 26)), isFalse);
    expect(item.isDueAt(DateTime.utc(2026, 8, 27)), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_row_mappers.dart';

void main() {
  test('maps a learning item row without leaking row maps to callers', () {
    final item = SupabaseLearningItemMapper.fromRow({
      'id': 'item-1',
      'user_id': 'user-1',
      'kind': 'expression',
      'content': 'prendre son temps',
      'part_of_speech': 'verb',
      'meaning': 'take one’s time',
      'context': null,
      'source': 'conversation',
      'first_production': 'I take my time.',
      'last_reviewed_at': '2026-08-26T12:00:00Z',
      'created_at': '2026-08-25T12:00:00Z',
      'updated_at': '2026-08-25T12:00:00Z',
      'next_review_at': '2026-08-25T12:00:00Z',
      'review_count': 0,
      'production_count': 0,
      'status': 'active',
    });

    expect(item.kind, LearningItemKind.expression);
    expect(item.status, LearningItemStatus.active);
    expect(item.source, 'conversation');
    expect(item.partOfSpeech, 'verb');
    expect(item.createdAt, DateTime.utc(2026, 8, 25, 12));
    expect(item.firstProduction, 'I take my time.');
    expect(item.lastReviewedAt, DateTime.utc(2026, 8, 26, 12));
  });

  test('maps nullable and rated review attempts', () {
    final attempt = SupabaseReviewAttemptMapper.fromRow({
      'id': 'attempt-1',
      'user_id': 'user-1',
      'learning_item_id': 'item-1',
      'review_submission_id': 'submission-1',
      'attempt_type': 'production',
      'rating': 'good',
      'response_text': 'Je prends mon temps.',
      'created_at': '2026-08-25T12:00:00Z',
    });

    expect(attempt.attemptType, ReviewAttemptType.production);
    expect(attempt.reviewSubmissionId, 'submission-1');
    expect(attempt.rating, ReviewRating.good);
    expect(attempt.responseText, 'Je prends mon temps.');
  });
}

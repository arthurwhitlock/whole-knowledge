import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/learning/review_repository.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_row_mappers.dart';

final class SupabaseReviewRepository implements ReviewRepository {
  const SupabaseReviewRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<LearningItem> completeReview({
    required LearningItem item,
    required String submissionId,
    required String responseText,
    required ReviewRating rating,
  }) async {
    final row = await _client
        .rpc<Map<String, dynamic>>(
          'complete_review',
          params: {
            'p_learning_item_id': item.id,
            'p_expected_review_count': item.reviewCount,
            'p_submission_id': submissionId,
            'p_response_text': responseText,
            'p_rating': rating.name,
          },
        )
        .single();

    return SupabaseLearningItemMapper.fromRow(row);
  }

  @override
  Future<List<ReviewAttempt>> listAttempts({
    required String learningItemId,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client
        .from('review_attempts')
        .select()
        .eq('learning_item_id', learningItemId)
        .order('created_at', ascending: false)
        .order('id')
        .range(offset, offset + limit - 1);
    return List.unmodifiable(rows.map(SupabaseReviewAttemptMapper.fromRow));
  }
}

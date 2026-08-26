import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/learning/capture_learning_item.dart';
import 'package:whole_knowledge/application/learning/learning_item_repository.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_row_mappers.dart';

final class SupabaseLearningItemRepository implements LearningItemRepository {
  const SupabaseLearningItemRepository(this._client);

  static const _pageSize = 1000;
  final SupabaseClient _client;

  @override
  Future<LearningItem> create(CaptureLearningItem capture) async {
    final userId = _requireUserId();
    final normalized = capture.normalized();
    final row = await _client
        .from('learning_items')
        .insert({
          'user_id': userId,
          'kind': normalized.kind.name,
          'content': normalized.content,
          'meaning': normalized.meaning,
          'context': normalized.context,
          'source': normalized.source,
        })
        .select()
        .single();

    return SupabaseLearningItemMapper.fromRow(row);
  }

  @override
  Future<List<LearningItem>> listAll() async {
    final items = <LearningItem>[];
    for (var from = 0; ; from += _pageSize) {
      final rows = await _client
          .from('learning_items')
          .select()
          .eq('status', LearningItemStatus.active.name)
          .order('created_at', ascending: false)
          .order('id')
          .range(from, from + _pageSize - 1);
      items.addAll(rows.map(SupabaseLearningItemMapper.fromRow));
      if (rows.length < _pageSize) break;
    }

    return List.unmodifiable(items);
  }

  @override
  Future<List<LearningItem>> listDue({required DateTime at}) async {
    final items = <LearningItem>[];
    final dueAt = at.toUtc().toIso8601String();
    for (var from = 0; ; from += _pageSize) {
      final rows = await _client
          .from('learning_items')
          .select()
          .eq('status', LearningItemStatus.active.name)
          .or('review_count.eq.0,next_review_at.lte.$dueAt')
          .order('next_review_at')
          .order('id')
          .range(from, from + _pageSize - 1);
      items.addAll(rows.map(SupabaseLearningItemMapper.fromRow));
      if (rows.length < _pageSize) break;
    }

    return List.unmodifiable(items);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('An authenticated session is required.');
    }
    return userId;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/application/capture/discovery_validation.dart';
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
          'part_of_speech': normalized.partOfSpeech,
          'meaning': normalized.meaning,
          'context': normalized.context,
          'source': normalized.source,
        })
        .select()
        .single();

    return SupabaseLearningItemMapper.fromRow(row);
  }

  @override
  Future<List<LearningItem>> findActiveBySurfaceForm(String content) async {
    _requireUserId();
    final key = DiscoveryValidation.surfaceMatchKey(content);
    if (key.isEmpty) return const [];
    try {
      final rows = await _client
          .from('learning_items')
          .select()
          .eq('status', LearningItemStatus.active.name)
          .eq('surface_match_key', key)
          .order('created_at', ascending: false)
          .order('id');
      return List.unmodifiable(rows.map(SupabaseLearningItemMapper.fromRow));
    } on PostgrestException catch (error) {
      throw DiscoveryFailure(
        DiscoveryFailureCode.libraryCheckUnavailable,
        metadata: {'code': error.code},
      );
    }
  }

  @override
  Future<DiscoveryCompletion> completeDiscovery(
    DiscoverySubmission submission,
  ) async {
    _requireUserId();
    final normalized = submission.normalized();
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'complete_discovery',
        params: {
          'p_submission_id': normalized.submissionId,
          'p_kind': normalized.kind.name,
          'p_content': normalized.content,
          'p_part_of_speech': normalized.partOfSpeech,
          'p_meaning': normalized.meaning,
          'p_context': normalized.context,
          'p_source': normalized.source,
          'p_first_production': normalized.firstProduction,
          'p_allow_existing_surface': normalized.allowExistingSurface,
        },
      );
      final row = response['item'];
      if (row is! Map) {
        throw const DiscoveryFailure(
          DiscoveryFailureCode.discoveryOutcomeUnknown,
        );
      }
      final item = SupabaseLearningItemMapper.fromRow(
        Map<String, dynamic>.from(row),
      );
      return switch (response['outcome']) {
        'created' => DiscoveryCreated(item),
        'replayed' => DiscoveryReplayed(item),
        'existing_surface' => DiscoveryExistingSurface(item),
        _ => throw const DiscoveryFailure(
          DiscoveryFailureCode.discoveryOutcomeUnknown,
        ),
      };
    } on DiscoveryFailure {
      rethrow;
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();
      final code = message.contains('different data')
          ? DiscoveryFailureCode.discoverySubmissionConflict
          : message.contains('authenticated session')
          ? DiscoveryFailureCode.sessionUnavailable
          : DiscoveryFailureCode.discoveryServiceUnavailable;
      throw DiscoveryFailure(code, metadata: {'code': error.code});
    }
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
  Future<List<LearningItem>> listDue({
    required DateTime at,
    int limit = 100,
  }) async {
    final dueAt = at.toUtc().toIso8601String();
    final rows = await _client
        .from('learning_items')
        .select()
        .eq('status', LearningItemStatus.active.name)
        .lte('next_review_at', dueAt)
        .order('next_review_at')
        .order('id')
        .limit(limit);
    return List.unmodifiable(rows.map(SupabaseLearningItemMapper.fromRow));
  }

  @override
  Future<List<LearningItem>> listRecent({required int limit}) async {
    final rows = await _client
        .from('learning_items')
        .select()
        .eq('status', LearningItemStatus.active.name)
        .order('created_at', ascending: false)
        .order('id')
        .limit(limit);
    return List.unmodifiable(rows.map(SupabaseLearningItemMapper.fromRow));
  }

  @override
  Future<List<LearningItem>> listCompletedBetween({
    required DateTime from,
    required DateTime to,
    required int limit,
  }) async {
    final rows = await _client
        .from('learning_items')
        .select('*, review_attempts!inner(created_at, attempt_type)')
        .eq('status', LearningItemStatus.active.name)
        .eq('review_attempts.attempt_type', 'production')
        .gte('review_attempts.created_at', from.toUtc().toIso8601String())
        .lt('review_attempts.created_at', to.toUtc().toIso8601String())
        .order('updated_at', ascending: false)
        .limit(limit);
    return List.unmodifiable(rows.map(SupabaseLearningItemMapper.fromRow));
  }

  @override
  Future<DateTime?> findNextScheduled({required DateTime after}) async {
    final rows = await _client
        .from('learning_items')
        .select('next_review_at')
        .eq('status', LearningItemStatus.active.name)
        .gt('next_review_at', after.toUtc().toIso8601String())
        .order('next_review_at')
        .limit(1);
    if (rows.isEmpty) return null;
    return DateTime.parse(rows.first['next_review_at'] as String).toUtc();
  }

  @override
  Future<List<LearningItem>> listPage({
    required int offset,
    required int limit,
  }) async {
    final rows = await _client
        .from('learning_items')
        .select()
        .eq('status', LearningItemStatus.active.name)
        .order('created_at', ascending: false)
        .order('id')
        .range(offset, offset + limit - 1);
    return List.unmodifiable(rows.map(SupabaseLearningItemMapper.fromRow));
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const DiscoveryFailure(DiscoveryFailureCode.sessionUnavailable);
    }
    return userId;
  }
}

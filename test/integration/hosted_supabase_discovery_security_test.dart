import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_learning_item_repository.dart';

void main() {
  final hostedUrl = Platform.environment['HOSTED_SUPABASE_URL'];
  final hostedKey = Platform.environment['HOSTED_SUPABASE_PUBLISHABLE_KEY'];
  final canRun = hostedUrl != null && hostedKey != null;
  final expectLegacyInsert =
      Platform.environment['EXPECT_LEGACY_INSERT_ALLOWED'] == 'true';

  test(
    'hosted Discovery enforces authored data and creation security',
    () async {
      final ownerClient = SupabaseClient(hostedUrl!, hostedKey!);
      final otherClient = SupabaseClient(hostedUrl, hostedKey);
      final ownerItems = SupabaseLearningItemRepository(ownerClient);
      final createdIds = <String>[];
      addTearDown(() async {
        if (createdIds.isNotEmpty) {
          await ownerClient
              .from('learning_items')
              .delete()
              .inFilter('id', createdIds);
        }
        await Future.wait([ownerClient.dispose(), otherClient.dispose()]);
      });

      final ownerAuth = await ownerClient.auth.signInAnonymously();
      final otherAuth = await otherClient.auth.signInAnonymously();
      final ownerId = ownerAuth.user!.id;
      expect(otherAuth.user!.id, isNot(ownerId));

      final runToken = DateTime.now().toUtc().microsecondsSinceEpoch;
      final content = 'WK hosted validation $runToken';
      final submissionId = _uuid();
      final created = await ownerItems.completeDiscovery(
        DiscoverySubmission(
          submissionId: submissionId,
          kind: LearningItemKind.vocabulary,
          content: '  $content  ',
          partOfSpeech: 'Noun',
          meaning: '  a live Frankfurt validation fixture  ',
          context: '  hosted test  ',
          source: '  M1 validation  ',
          firstProduction: '  I validated this word in Frankfurt.  ',
          allowExistingSurface: false,
        ),
      );
      expect(created, isA<DiscoveryCreated>());
      final createdItem = created.item;
      createdIds.add(createdItem.id);
      expect(createdItem.userId, ownerId);
      expect(createdItem.content, content);
      expect(createdItem.partOfSpeech, 'noun');
      expect(createdItem.meaning, 'a live Frankfurt validation fixture');
      expect(createdItem.context, 'hosted test');
      expect(createdItem.source, 'M1 validation');
      expect(
        createdItem.firstProduction,
        'I validated this word in Frankfurt.',
      );
      expect(
        createdItem.nextReviewAt.difference(createdItem.createdAt),
        closeToDuration(const Duration(hours: 24)),
      );

      final replayed = await ownerItems.completeDiscovery(
        DiscoverySubmission(
          submissionId: submissionId,
          kind: LearningItemKind.vocabulary,
          content: content,
          partOfSpeech: 'noun',
          meaning: 'a live Frankfurt validation fixture',
          context: 'hosted test',
          source: 'M1 validation',
          firstProduction: 'I validated this word in Frankfurt.',
          allowExistingSurface: false,
        ),
      );
      expect(replayed, isA<DiscoveryReplayed>());
      expect(replayed.item.id, createdItem.id);
      expect(
        await ownerClient
            .from('learning_items')
            .select('id')
            .eq('discovery_submission_id', submissionId),
        hasLength(1),
      );

      await expectLater(
        ownerItems.completeDiscovery(
          DiscoverySubmission(
            submissionId: submissionId,
            kind: LearningItemKind.vocabulary,
            content: content,
            partOfSpeech: 'noun',
            meaning: 'changed data must not overwrite the saved item',
            context: 'hosted test',
            source: 'M1 validation',
            firstProduction: 'I validated this word in Frankfurt.',
            allowExistingSurface: false,
          ),
        ),
        throwsA(
          isA<DiscoveryFailure>().having(
            (failure) => failure.code,
            'code',
            DiscoveryFailureCode.discoverySubmissionConflict,
          ),
        ),
      );
      expect(
        (await ownerClient
            .from('learning_items')
            .select('meaning')
            .eq('id', createdItem.id)
            .single())['meaning'],
        'a live Frankfurt validation fixture',
      );

      final deferred = await ownerItems.completeDiscovery(
        DiscoverySubmission(
          submissionId: _uuid(),
          kind: LearningItemKind.expression,
          content: '$content deferred',
          meaning: 'a deferred live fixture',
          allowExistingSurface: false,
        ),
      );
      expect(deferred, isA<DiscoveryCreated>());
      createdIds.add(deferred.item.id);
      expect(
        deferred.item.nextReviewAt.difference(deferred.item.createdAt),
        closeToDuration(Duration.zero),
      );

      expect(
        await ownerItems.findActiveBySurfaceForm(
          '  ${content.toUpperCase().replaceAll(' ', '   ')}  ',
        ),
        hasLength(1),
      );
      final existing = await ownerItems.completeDiscovery(
        DiscoverySubmission(
          submissionId: _uuid(),
          kind: LearningItemKind.vocabulary,
          content: content.toUpperCase(),
          meaning: 'an ordinary duplicate',
          allowExistingSurface: false,
        ),
      );
      expect(existing, isA<DiscoveryExistingSurface>());
      expect(existing.item.id, createdItem.id);

      final additional = await ownerItems.completeDiscovery(
        DiscoverySubmission(
          submissionId: _uuid(),
          kind: LearningItemKind.vocabulary,
          content: content.toUpperCase(),
          meaning: 'an explicitly additional sense',
          allowExistingSurface: true,
        ),
      );
      expect(additional, isA<DiscoveryCreated>());
      createdIds.add(additional.item.id);
      expect(await ownerItems.findActiveBySurfaceForm(content), hasLength(2));

      expect(
        await otherClient
            .from('learning_items')
            .select('id')
            .inFilter('id', createdIds),
        isEmpty,
      );
      await expectLater(
        otherClient
            .from('learning_items')
            .update({'meaning': 'cross-owner mutation'})
            .eq('id', createdItem.id),
        throwsA(isA<PostgrestException>()),
      );
      expect(
        await otherClient
            .from('learning_items')
            .delete()
            .eq('id', createdItem.id)
            .select(),
        isEmpty,
      );
      await expectLater(
        otherClient.from('learning_items').insert({
          'user_id': ownerId,
          'kind': 'vocabulary',
          'content': '$content forged owner',
          'meaning': 'must not be created for another owner',
        }),
        throwsA(isA<PostgrestException>()),
      );

      for (final invalid in <Map<String, Object?>>[
        _params(submissionId: _uuid(), content: '   '),
        _params(submissionId: _uuid(), content: '...'),
        _params(submissionId: _uuid(), content: 'x' * 2001),
        _params(submissionId: _uuid(), meaning: '   '),
        _params(submissionId: _uuid(), meaning: 'x' * 4001),
        _params(submissionId: _uuid(), partOfSpeech: 'x' * 81),
        _params(submissionId: _uuid(), context: 'x' * 4001),
        _params(submissionId: _uuid(), source: 'x' * 1001),
        _params(submissionId: _uuid(), firstProduction: 'x' * 10001),
        _params(submissionId: _uuid(), kind: 'unsupported'),
      ]) {
        await expectLater(
          ownerClient.rpc<Object?>('complete_discovery', params: invalid),
          throwsA(
            isA<PostgrestException>().having(
              (error) => error.code,
              'code',
              '22023',
            ),
          ),
        );
      }

      await expectLater(
        ownerClient.rpc<Object?>(
          'complete_discovery',
          params: {
            ..._params(submissionId: _uuid()),
            'p_user_id': otherAuth.user!.id,
          },
        ),
        throwsA(isA<PostgrestException>()),
      );

      await expectLater(
        ownerClient.from('learning_items').insert({
          'user_id': ownerId,
          'kind': 'vocabulary',
          'content': '$content protected fields',
          'meaning': 'protected fields must not be client-authored',
          'review_count': 50,
          'production_count': 50,
          'next_review_at': DateTime.utc(2099).toIso8601String(),
          'first_production': 'forged production',
          'discovery_submission_id': _uuid(),
        }),
        throwsA(isA<PostgrestException>()),
      );

      final directInsert = ownerClient
          .from('learning_items')
          .insert({
            'user_id': ownerId,
            'kind': 'vocabulary',
            'content': '$content legacy direct insert',
            'meaning': 'staged legacy boundary fixture',
          })
          .select('id')
          .single();
      if (expectLegacyInsert) {
        final directRow = await directInsert;
        createdIds.add(directRow['id']! as String);
      } else {
        await expectLater(directInsert, throwsA(isA<PostgrestException>()));
      }
    },
    skip: canRun
        ? false
        : 'Requires HOSTED_SUPABASE_URL and '
              'HOSTED_SUPABASE_PUBLISHABLE_KEY.',
  );
}

Matcher closeToDuration(Duration expected) => predicate<Duration>(
  (actual) => (actual - expected).abs() < const Duration(seconds: 2),
  'within two seconds of $expected',
);

Map<String, Object?> _params({
  required String submissionId,
  String kind = 'vocabulary',
  String content = 'hosted validation input',
  String? partOfSpeech = 'noun',
  String meaning = 'a hosted validation meaning',
  String? context,
  String? source,
  String? firstProduction,
}) => {
  'p_submission_id': submissionId,
  'p_kind': kind,
  'p_content': content,
  'p_part_of_speech': partOfSpeech,
  'p_meaning': meaning,
  'p_context': context,
  'p_source': source,
  'p_first_production': firstProduction,
  'p_allow_existing_surface': false,
};

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

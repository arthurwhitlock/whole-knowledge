import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:whole_knowledge/application/capture/lexical_provider.dart';
import 'package:whole_knowledge/infrastructure/dictionary/english_dictionary_api_provider.dart';

void main() {
  test(
    'maps multiple parts of speech and senses from the provider schema',
    () async {
      final provider = EnglishDictionaryApiProvider(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/words/record');
          return http.Response(
            '{"partsOfSpeech":['
            '{"partOfSpeech":"noun","senses":[{"definition":"A stored account."}]},'
            '{"partOfSpeech":"verb","senses":[{"definition":"To preserve information."}]}'
            ']}',
            200,
          );
        }),
      );

      final result = await provider.lookup(' Record ');

      expect(result.senses, hasLength(2));
      expect(result.senses.first.partOfSpeech, 'noun');
      expect(result.senses.last.partOfSpeech, 'verb');
    },
  );

  test('turns a missing entry into a manual-fallback message', () async {
    final provider = EnglishDictionaryApiProvider(
      client: MockClient((_) async => http.Response('', 404)),
    );

    expect(
      provider.lookup('notaword'),
      throwsA(
        isA<LexicalLookupException>().having(
          (error) => error.message,
          'message',
          contains('manually'),
        ),
      ),
    );
  });
}

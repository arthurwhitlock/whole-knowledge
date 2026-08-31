import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
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
            '{"partOfSpeech":"noun","senses":[{"definition":"A stored account.","examples":[{"text":"Keep a record."}]}]},'
            '{"partOfSpeech":"verb","senses":[{"definition":"To preserve information."}]}'
            ']}',
            200,
          );
        }),
      );

      final result = await provider.lookup(' Record ');

      expect(result.senses, hasLength(2));
      expect(result.senses.first.partOfSpeech, 'noun');
      expect(result.senses.first.example, 'Keep a record.');
      expect(result.senses.last.partOfSpeech, 'verb');
      expect(result.groups.map((group) => group.name), ['noun', 'verb']);
    },
  );

  test('turns a missing entry into a manual-fallback message', () async {
    final provider = EnglishDictionaryApiProvider(
      client: MockClient((_) async => http.Response('', 404)),
    );

    expect(
      provider.lookup('notaword'),
      throwsA(
        isA<DiscoveryFailure>().having(
          (error) => error.code,
          'code',
          DiscoveryFailureCode.lexicalEntryNotFound,
        ),
      ),
    );
  });

  test('coalesces identical in-flight lookups', () async {
    final completer = Completer<http.Response>();
    final provider = EnglishDictionaryApiProvider(
      client: MockClient((_) => completer.future),
    );

    final first = provider.lookup('Record');
    final second = provider.lookup(' record ');
    completer.complete(
      http.Response(
        '{"partsOfSpeech":[{"partOfSpeech":"noun","senses":'
        '[{"definition":"A stored account."}]}]}',
        200,
      ),
    );

    expect(identical(first, second), isTrue);
    expect((await first).senses, hasLength(1));
  });

  test('maps rate limits and malformed payloads to typed failures', () async {
    final rateLimited = EnglishDictionaryApiProvider(
      client: MockClient((_) async => http.Response('', 429)),
    );
    final malformed = EnglishDictionaryApiProvider(
      client: MockClient((_) async => http.Response('{bad', 200)),
    );

    await expectLater(
      rateLimited.lookup('record'),
      throwsA(
        isA<DiscoveryFailure>().having(
          (error) => error.code,
          'code',
          DiscoveryFailureCode.lexicalRateLimited,
        ),
      ),
    );
    await expectLater(
      malformed.lookup('record'),
      throwsA(
        isA<DiscoveryFailure>().having(
          (error) => error.code,
          'code',
          DiscoveryFailureCode.lexicalPayloadInvalid,
        ),
      ),
    );
  });

  test('decodes a valid one-chunk streamed response', () async {
    final bytes = utf8.encode(
      '{"partsOfSpeech":[{"partOfSpeech":"noun","senses":'
      '[{"definition":"A streamed account."}]}]}',
    );
    final provider = EnglishDictionaryApiProvider(
      client: _StreamClient(
        (_) async => http.StreamedResponse(Stream.value(bytes), 200),
      ),
    );

    final lookup = await provider.lookup('record');

    expect(lookup.senses.single.definition, 'A streamed account.');
  });

  test('rejects cumulative streamed bytes above the hard cap', () async {
    final first = List<int>.filled(
      EnglishDictionaryApiProvider.maximumBodyBytes ~/ 2 + 1,
      1,
    );
    final second = List<int>.filled(
      EnglishDictionaryApiProvider.maximumBodyBytes ~/ 2 + 1,
      1,
    );
    final provider = EnglishDictionaryApiProvider(
      client: _StreamClient(
        (_) async =>
            http.StreamedResponse(Stream.fromIterable([first, second]), 200),
      ),
    );

    await expectLater(
      provider.lookup('record'),
      throwsA(
        isA<DiscoveryFailure>().having(
          (error) => error.code,
          'code',
          DiscoveryFailureCode.lexicalResponseTooLarge,
        ),
      ),
    );
  });

  test('rejects an oversized declared content length before reading', () async {
    var listened = false;
    final stream = Stream<List<int>>.multi((controller) {
      listened = true;
      controller.close();
    });
    final provider = EnglishDictionaryApiProvider(
      client: _StreamClient(
        (_) async => http.StreamedResponse(
          stream,
          200,
          contentLength: EnglishDictionaryApiProvider.maximumBodyBytes + 1,
        ),
      ),
    );

    await expectLater(
      provider.lookup('record'),
      throwsA(
        isA<DiscoveryFailure>().having(
          (error) => error.code,
          'code',
          DiscoveryFailureCode.lexicalResponseTooLarge,
        ),
      ),
    );
    expect(listened, isFalse);
  });

  test('maps a stalled response stream abort to timeout', () async {
    final provider = EnglishDictionaryApiProvider(
      requestDeadline: const Duration(milliseconds: 5),
      client: _StreamClient((request) async {
        final abortable = request as http.AbortableRequest;
        final controller = StreamController<List<int>>();
        unawaited(
          abortable.abortTrigger!.then((_) {
            controller.addError(http.RequestAbortedException(request.url));
            return controller.close();
          }),
        );
        return http.StreamedResponse(controller.stream, 200);
      }),
    );

    await expectLater(
      provider.lookup('record'),
      throwsA(
        isA<DiscoveryFailure>().having(
          (error) => error.code,
          'code',
          DiscoveryFailureCode.lexicalTimedOut,
        ),
      ),
    );
  });
}

final class _StreamClient extends http.BaseClient {
  _StreamClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}

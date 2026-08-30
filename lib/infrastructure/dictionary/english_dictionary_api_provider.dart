import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
import 'package:whole_knowledge/application/capture/lexical_provider.dart';

final class EnglishDictionaryApiProvider implements LexicalProvider {
  EnglishDictionaryApiProvider({
    http.Client? client,
    this.requestDeadline = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       assert(requestDeadline > Duration.zero);

  static const maximumBodyBytes = 1024 * 1024;
  final http.Client _client;
  final Duration requestDeadline;
  final Map<String, Future<LexicalLookup>> _inFlight = {};

  @override
  String get attribution =>
      'English definitions from EnglishDictionaryAPI · Wiktionary data, '
      'CC BY-SA 4.0';

  @override
  Future<LexicalLookup> lookup(String term) {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const DiscoveryFailure(
        DiscoveryFailureCode.discoveryValidationRejected,
        metadata: {'field': 'content'},
      );
    }
    return _inFlight.putIfAbsent(normalized, () async {
      try {
        return await _request(normalized);
      } finally {
        _inFlight.remove(normalized);
      }
    });
  }

  Future<LexicalLookup> _request(String term) async {
    final abortTrigger = Completer<void>();
    var deadlineExpired = false;
    final timer = Timer(requestDeadline, () {
      deadlineExpired = true;
      if (!abortTrigger.isCompleted) abortTrigger.complete();
    });
    final request = http.AbortableRequest(
      'GET',
      Uri.https('englishdictionaryapi.com', '/api/v1/words/$term'),
      abortTrigger: abortTrigger.future,
    );
    try {
      final response = await _client.send(request);
      if (response.statusCode == 404) {
        throw const DiscoveryFailure(DiscoveryFailureCode.lexicalEntryNotFound);
      }
      if (response.statusCode == 429) {
        throw const DiscoveryFailure(DiscoveryFailureCode.lexicalRateLimited);
      }
      if (response.statusCode != 200) {
        throw DiscoveryFailure(
          DiscoveryFailureCode.lexicalServiceUnavailable,
          metadata: {'statusGroup': response.statusCode ~/ 100},
        );
      }
      final contentLength = response.contentLength;
      if (contentLength != null && contentLength > maximumBodyBytes) {
        if (!abortTrigger.isCompleted) abortTrigger.complete();
        throw const DiscoveryFailure(
          DiscoveryFailureCode.lexicalResponseTooLarge,
        );
      }

      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        if (bytes.length + chunk.length > maximumBodyBytes) {
          if (!abortTrigger.isCompleted) abortTrigger.complete();
          throw const DiscoveryFailure(
            DiscoveryFailureCode.lexicalResponseTooLarge,
          );
        }
        bytes.add(chunk);
      }
      return _decode(term, bytes.takeBytes());
    } on DiscoveryFailure {
      rethrow;
    } on http.RequestAbortedException {
      throw DiscoveryFailure(
        deadlineExpired
            ? DiscoveryFailureCode.lexicalTimedOut
            : DiscoveryFailureCode.lexicalServiceUnavailable,
      );
    } on FormatException {
      throw const DiscoveryFailure(DiscoveryFailureCode.lexicalPayloadInvalid);
    } on Object {
      throw const DiscoveryFailure(
        DiscoveryFailureCode.lexicalServiceUnavailable,
      );
    } finally {
      timer.cancel();
    }
  }

  LexicalLookup _decode(String term, Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    final senses = <LexicalSense>[];
    final parts = decoded['partsOfSpeech'];
    if (parts is List) {
      for (final part in parts.whereType<Map<String, dynamic>>()) {
        final name =
            part['partOfSpeech'] as String? ??
            part['part_of_speech'] as String? ??
            part['name'] as String?;
        final rawSenses = part['senses'];
        if (name == null || rawSenses is! List) continue;
        for (final rawSense in rawSenses.whereType<Map<String, dynamic>>()) {
          final definition = rawSense['definition'] as String?;
          if (definition == null || definition.trim().isEmpty) continue;
          senses.add(
            LexicalSense(
              partOfSpeech: name.trim().toLowerCase(),
              definition: definition.trim(),
              example: _firstExample(rawSense),
            ),
          );
        }
      }
    }
    if (senses.isEmpty) throw const FormatException();
    return LexicalLookup(term: term, senses: List.unmodifiable(senses));
  }

  String? _firstExample(Map<String, dynamic> rawSense) {
    final direct = rawSense['example'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();
    final examples = rawSense['examples'];
    if (examples is List) {
      for (final example in examples) {
        if (example is String && example.trim().isNotEmpty) {
          return example.trim();
        }
        if (example is Map) {
          final text = example['text'];
          if (text is String && text.trim().isNotEmpty) return text.trim();
        }
      }
    }
    return null;
  }
}

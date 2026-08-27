import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:whole_knowledge/application/capture/lexical_provider.dart';

final class EnglishDictionaryApiProvider implements LexicalProvider {
  EnglishDictionaryApiProvider({http.Client? client})
    : _client = client ?? http.Client();

  static const _maximumBodyBytes = 1024 * 1024;
  final http.Client _client;
  final Map<String, Future<LexicalLookup>> _inFlight = {};

  @override
  String get attribution =>
      'English definitions from EnglishDictionaryAPI · Wiktionary data, '
      'CC BY-SA 4.0';

  @override
  Future<LexicalLookup> lookup(String term) {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const LexicalLookupException('Enter an English word first.');
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
    final request = http.Request(
      'GET',
      Uri.https('englishdictionaryapi.com', '/api/v1/words/$term'),
    );
    final response = await _client
        .send(request)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw const LexicalLookupException(
            'English lookup timed out. Add a meaning manually.',
          ),
        );
    if (response.statusCode == 404) {
      throw const LexicalLookupException(
        'No English entry found. Add a meaning manually.',
      );
    }
    if (response.statusCode != 200) {
      throw const LexicalLookupException(
        'English lookup is unavailable. Add a meaning manually.',
      );
    }

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      if (bytes.length > _maximumBodyBytes) {
        throw const LexicalLookupException(
          'The lookup response was too large.',
        );
      }
    }
    try {
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
            if (definition != null && definition.trim().isNotEmpty) {
              senses.add(
                LexicalSense(
                  partOfSpeech: name.trim().toLowerCase(),
                  definition: definition.trim(),
                ),
              );
            }
          }
        }
      }
      if (senses.isEmpty) throw const FormatException();
      return LexicalLookup(term: term, senses: List.unmodifiable(senses));
    } on LexicalLookupException {
      rethrow;
    } on Object {
      throw const LexicalLookupException(
        'The English lookup returned an unreadable entry. Add it manually.',
      );
    }
  }
}

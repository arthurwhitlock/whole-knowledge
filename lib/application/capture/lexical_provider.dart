final class LexicalSense {
  const LexicalSense({
    required this.partOfSpeech,
    required this.definition,
    this.example,
  });

  final String partOfSpeech;
  final String definition;
  final String? example;
}

final class LexicalPartOfSpeechGroup {
  const LexicalPartOfSpeechGroup({required this.name, required this.senses});

  final String name;
  final List<LexicalSense> senses;
}

final class LexicalLookup {
  const LexicalLookup({required this.term, required this.senses});

  final String term;
  final List<LexicalSense> senses;

  List<LexicalPartOfSpeechGroup> get groups {
    final grouped = <String, List<LexicalSense>>{};
    for (final sense in senses) {
      grouped.putIfAbsent(sense.partOfSpeech, () => []).add(sense);
    }
    return List.unmodifiable(
      grouped.entries.map(
        (entry) => LexicalPartOfSpeechGroup(
          name: entry.key,
          senses: List.unmodifiable(entry.value),
        ),
      ),
    );
  }
}

abstract interface class LexicalProvider {
  String get attribution;

  Future<LexicalLookup> lookup(String term);
}

final class LexicalLookupException implements Exception {
  const LexicalLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
